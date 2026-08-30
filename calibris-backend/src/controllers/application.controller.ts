import { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "../db";
import { transitionApplication } from "../services/status.service";
import { uploadFile } from "../services/storage.service";

const createApplicationSchema = z.object({
  instrumentId: z.string(),
});

export async function createApplication(req: Request, res: Response) {
  const parsed = createApplicationSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  const vendorId = req.auth!.sub;

  const instrument = await prisma.instrument.findFirst({
    where: { id: parsed.data.instrumentId, vendorId },
  });
  if (!instrument) return res.status(404).json({ error: "Instrument not found for this vendor" });

  const application = await prisma.application.create({
    data: { vendorId, instrumentId: instrument.id, status: "SUBMITTED" },
  });

  await prisma.applicationStatusHistory.create({
    data: {
      applicationId: application.id,
      toStatus: "SUBMITTED",
      changedByType: "USER",
      changedById: vendorId,
      note: "Application submitted",
    },
  });

  res.status(201).json(application);
}

const DOCUMENT_TYPES = ["INSTRUMENT_PHOTO", "SUPPORTING_DOCUMENT", "ID_PROOF", "OTHER"] as const;

export async function uploadDocument(req: Request, res: Response) {
  const { applicationId } = req.params;
  const docType = req.body.type as (typeof DOCUMENT_TYPES)[number];
  if (!DOCUMENT_TYPES.includes(docType)) {
    return res.status(400).json({ error: `type must be one of ${DOCUMENT_TYPES.join(", ")}` });
  }
  if (!req.file) return res.status(400).json({ error: "No file uploaded (field name: file)" });

  const vendorId = req.auth!.sub;
  const application = await prisma.application.findFirst({ where: { id: applicationId, vendorId } });
  if (!application) return res.status(404).json({ error: "Application not found" });

  const { url } = await uploadFile(req.file.buffer, req.file.originalname, req.file.mimetype);

  const document = await prisma.document.create({
    data: {
      applicationId,
      type: docType,
      url,
      originalName: req.file.originalname,
      mimeType: req.file.mimetype,
      sizeBytes: req.file.size,
    },
  });

  // Once both an instrument photo and a supporting document are present,
  // auto-advance the application out of DOCUMENTS_PENDING.
  const docs = await prisma.document.findMany({ where: { applicationId } });
  const hasPhoto = docs.some((d) => d.type === "INSTRUMENT_PHOTO");
  const hasSupport = docs.some((d) => d.type === "SUPPORTING_DOCUMENT");

  if (application.status === "SUBMITTED") {
    await transitionApplication(applicationId, "DOCUMENTS_PENDING", { type: "SYSTEM" }, "First document uploaded");
  }
  if (hasPhoto && hasSupport) {
    const fresh = await prisma.application.findUnique({ where: { id: applicationId } });
    if (fresh?.status === "DOCUMENTS_PENDING") {
      await transitionApplication(applicationId, "DOCUMENTS_VERIFIED", { type: "SYSTEM" }, "Required documents complete");
    }
  }

  res.status(201).json(document);
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
