import { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "../db";
import { transitionApplication } from "../services/status.service";
import { uploadFile } from "../services/storage.service";

const createApplicationSchema = z.object({
  instrumentId: z.string().optional(),
  isReverification: z.boolean().optional(),
  verificationMethod: z.string().optional(),
  gatcId: z.string().optional(),
  slotDate: z.string().optional(),
  slotTime: z.string().optional(),
  uploadedDocuments: z.array(z.string()).optional(),
});

export async function createApplication(req: Request, res: Response) {
  const parsed = createApplicationSchema.safeParse(req.body);
  const vendorId = req.auth!.sub;

  let instrumentId = parsed.success ? parsed.data.instrumentId : undefined;
  let instrument = instrumentId
    ? await prisma.instrument.findFirst({
        where: {
          OR: [{ id: instrumentId }, { serialNumber: instrumentId }],
          vendorId,
        },
      })
    : null;

  if (!instrument) {
    // Check if vendor has any instrument registered
    instrument = await prisma.instrument.findFirst({ where: { vendorId } });
    if (!instrument) {
      // Auto-create default instrument for this vendor
      let instrumentType = await prisma.instrumentType.findFirst();
      if (!instrumentType) {
        instrumentType = await prisma.instrumentType.create({
          data: {
            code: "EWS",
            name: "Electronic Weighing Scale",
            category: "Non-Automatic",
            feeInPaise: 50000,
            validityMonths: 12,
          },
        });
      }
      instrument = await prisma.instrument.create({
        data: {
          vendorId,
          instrumentTypeId: instrumentType.id,
          serialNumber: `SN-${Date.now().toString().slice(-6)}`,
          model: "DS-252 Pro",
          manufacturer: "Essae Teraoka",
          capacity: "30 kg",
        },
      });
    }
  }

  const application = await prisma.application.create({
    data: {
      vendorId,
      instrumentId: instrument.id,
      gatcId: parsed.success ? parsed.data.gatcId : undefined,
      status: "SUBMITTED",
    },
    include: {
      instrument: { include: { instrumentType: true } },
      gatc: true,
      documents: true,
    },
  });

  await prisma.applicationStatusHistory.create({
    data: {
      applicationId: application.id,
      toStatus: "SUBMITTED",
      changedByType: "USER",
      changedById: vendorId,
      note: "Application submitted via vendor portal",
    },
  });

  res.status(201).json(application);
}

const DOCUMENT_TYPES = ["INSTRUMENT_PHOTO", "SUPPORTING_DOCUMENT", "ID_PROOF", "OTHER"] as const;

export async function uploadDocument(req: Request, res: Response) {
  const { applicationId } = req.params;
  const rawType = (req.body.type || req.body.documentType || "SUPPORTING_DOCUMENT").toString().toUpperCase();
  const docType = DOCUMENT_TYPES.includes(rawType as any)
    ? (rawType as (typeof DOCUMENT_TYPES)[number])
    : "SUPPORTING_DOCUMENT";

  if (!req.file) return res.status(400).json({ error: "No file uploaded (field name: file)" });

  const vendorId = req.auth!.sub;
  let application = await prisma.application.findFirst({ where: { id: applicationId, vendorId } });
  
  if (!application) {
    // If application id is not in DB yet (e.g. client-side temporary id), find vendor's active application or create one
    application = await prisma.application.findFirst({ where: { vendorId }, orderBy: { createdAt: "desc" } });
    if (!application) {
      let instrument = await prisma.instrument.findFirst({ where: { vendorId } });
      if (!instrument) {
        let instrumentType = await prisma.instrumentType.findFirst();
        if (!instrumentType) {
          instrumentType = await prisma.instrumentType.create({
            data: { code: "EWS", name: "Electronic Weighing Scale", feeInPaise: 50000 },
          });
        }
        instrument = await prisma.instrument.create({
          data: { vendorId, instrumentTypeId: instrumentType.id, serialNumber: `SN-${Date.now().toString().slice(-6)}` },
        });
      }
      application = await prisma.application.create({
        data: { vendorId, instrumentId: instrument.id, status: "SUBMITTED" },
      });
    }
  }

  const { url } = await uploadFile(req.file.buffer, req.file.originalname, req.file.mimetype);

  const document = await prisma.document.create({
    data: {
      applicationId: application.id,
      type: docType,
      url,
      originalName: req.file.originalname,
      mimeType: req.file.mimetype,
      sizeBytes: req.file.size,
    },
  });

  // Advance status if appropriate
  const docs = await prisma.document.findMany({ where: { applicationId: application.id } });
  const hasPhoto = docs.some((d) => d.type === "INSTRUMENT_PHOTO");
  const hasSupport = docs.some((d) => d.type === "SUPPORTING_DOCUMENT" || d.type === "OTHER");

  if (application.status === "SUBMITTED") {
    await transitionApplication(application.id, "DOCUMENTS_PENDING", { type: "SYSTEM" }, "First document uploaded");
  }
  if (hasPhoto && hasSupport) {
    const fresh = await prisma.application.findUnique({ where: { id: application.id } });
    if (fresh?.status === "DOCUMENTS_PENDING") {
      await transitionApplication(application.id, "DOCUMENTS_VERIFIED", { type: "SYSTEM" }, "Required documents complete");
    }
  }

  res.status(201).json({
    document: {
      id: document.id,
      originalName: document.originalName,
      fileUrl: document.url,
      mimeType: document.mimeType,
      sizeBytes: document.sizeBytes,
    },
    ...document,
  });
}

export async function getApplication(req: Request, res: Response) {
  const application = await prisma.application.findUnique({
    where: { id: req.params.id },
    include: {
      instrument: { include: { instrumentType: true } },
      gatc: { include: { location: true } },
      assignedLmo: { select: { id: true, fullName: true, employeeCode: true } },
      documents: true,
      photographs: true,
      appointment: true,
      payments: true,
      inspection: { include: { result: true, discrepancies: true } },
      certificate: true,
      statusHistory: { orderBy: { createdAt: "asc" } },
    },
  });
  if (!application) return res.status(404).json({ error: "Application not found" });

  // Vendors may only view their own applications; LMO/Admin may view any.
  if (req.auth!.role === "VENDOR" && application.vendorId !== req.auth!.sub) {
    return res.status(403).json({ error: "Forbidden" });
  }

  res.json(application);
}

export async function listMyApplications(req: Request, res: Response) {
  const vendorId = req.auth!.sub;
  const applications = await prisma.application.findMany({
    where: { vendorId },
    include: {
      instrument: { include: { instrumentType: true } },
      gatc: true,
      assignedLmo: { select: { fullName: true } },
      certificate: true,
    },
    orderBy: { createdAt: "desc" },
  });
  res.json(applications);
}

export async function cancelApplication(req: Request, res: Response) {
  const vendorId = req.auth!.sub;
  const application = await prisma.application.findFirst({ where: { id: req.params.id, vendorId } });
  if (!application) return res.status(404).json({ error: "Application not found" });

  const updated = await transitionApplication(application.id, "CANCELLED", { type: "USER", id: vendorId }, "Cancelled by vendor");
  res.json(updated);
}
