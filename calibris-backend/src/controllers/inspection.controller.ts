import { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "../db";
import { transitionApplication } from "../services/status.service";
import { uploadFile } from "../services/storage.service";

/** Applications assigned to the logged-in LMO that are ready for inspection. */
export async function myQueue(req: Request, res: Response) {
  const lmoId = req.auth!.sub;
  const applications = await prisma.application.findMany({
    where: {
      assignedLmoId: lmoId,
      status: { in: ["LMO_ASSIGNED", "INSPECTION_IN_PROGRESS"] },
    },
    include: {
      vendor: { select: { fullName: true, businessName: true, phone: true } },
      instrument: { include: { instrumentType: true } },
      gatc: true,
      appointment: true,
      documents: true,
    },
    orderBy: { updatedAt: "asc" },
  });
  res.json(applications);
}

export async function startInspection(req: Request, res: Response) {
  const lmoId = req.auth!.sub;
  const applicationId = req.params.applicationId;

  const application = await prisma.application.findFirst({ where: { id: applicationId, assignedLmoId: lmoId } });
  if (!application) return res.status(404).json({ error: "Application not assigned to you" });

  const bodySchema = z.object({ gpsLatitude: z.number(), gpsLongitude: z.number() });
  const parsed = bodySchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

  const inspection = await prisma.inspection.upsert({
    where: { applicationId },
    create: {
      applicationId,
      lmoId,
      startedAt: new Date(),
      gpsLatitude: parsed.data.gpsLatitude,
      gpsLongitude: parsed.data.gpsLongitude,
    },
    update: {
      startedAt: new Date(),
      gpsLatitude: parsed.data.gpsLatitude,
      gpsLongitude: parsed.data.gpsLongitude,
    },
  });

  await transitionApplication(applicationId, "INSPECTION_IN_PROGRESS", { type: "LMO", id: lmoId }, "Inspection started");

  res.status(201).json(inspection);
}

export async function addDiscrepancy(req: Request, res: Response) {
  const lmoId = req.auth!.sub;
  const applicationId = req.params.applicationId;

  const inspection = await prisma.inspection.findFirst({ where: { applicationId, lmoId } });
  if (!inspection) return res.status(404).json({ error: "Inspection not found" });

  const bodySchema = z.object({
    description: z.string().min(1),
    severity: z.enum(["MINOR", "MAJOR", "CRITICAL"]).default("MINOR"),
  });
  const parsed = bodySchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

  let photoUrl: string | undefined;
  if (req.file) {
    const uploaded = await uploadFile(req.file.buffer, req.file.originalname, req.file.mimetype);
    photoUrl = uploaded.url;
  }

  const discrepancy = await prisma.discrepancy.create({
    data: { inspectionId: inspection.id, ...parsed.data, photoUrl },
  });

  res.status(201).json(discrepancy);
}

export async function uploadInspectionPhoto(req: Request, res: Response) {
  const lmoId = req.auth!.sub;
  const applicationId = req.params.applicationId;
  const application = await prisma.application.findFirst({ where: { id: applicationId, assignedLmoId: lmoId } });
  if (!application) return res.status(404).json({ error: "Application not assigned to you" });
  if (!req.file) return res.status(400).json({ error: "No file uploaded (field name: file)" });

  const { url } = await uploadFile(req.file.buffer, req.file.originalname, req.file.mimetype);
  const bodySchema = z.object({
    caption: z.string().optional(),
    gpsLatitude: z.coerce.number().optional(),
    gpsLongitude: z.coerce.number().optional(),
  });
  const parsed = bodySchema.safeParse(req.body);

  const photo = await prisma.photograph.create({
    data: {
      applicationId,
      url,
      caption: parsed.success ? parsed.data.caption : undefined,
      takenByType: "LMO",
      gpsLatitude: parsed.success ? parsed.data.gpsLatitude : undefined,
      gpsLongitude: parsed.success ? parsed.data.gpsLongitude : undefined,
    },
  });

  res.status(201).json(photo);
}

const submitResultSchema = z.object({
  status: z.enum(["PASSED", "FAILED"]),
  remarks: z.string().optional(),
});

export async function submitResult(req: Request, res: Response) {
  const lmoId = req.auth!.sub;
  const applicationId = req.params.applicationId;

  const inspection = await prisma.inspection.findFirst({ where: { applicationId, lmoId } });
  if (!inspection) return res.status(404).json({ error: "Inspection not found" });

  const parsed = submitResultSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

  const result = await prisma.$transaction(async (tx) => {
    await tx.inspection.update({ where: { id: inspection.id }, data: { completedAt: new Date() } });
    const r = await tx.inspectionResult.upsert({
      where: { inspectionId: inspection.id },
      create: { inspectionId: inspection.id, status: parsed.data.status, remarks: parsed.data.remarks },
      update: { status: parsed.data.status, remarks: parsed.data.remarks },
    });
    return r;
  });

  await transitionApplication(applicationId, "INSPECTION_COMPLETE", { type: "LMO", id: lmoId }, "Inspection complete, awaiting result recording");
  await transitionApplication(
    applicationId,
    parsed.data.status === "PASSED" ? "PASSED" : "FAILED",
    { type: "LMO", id: lmoId },
    parsed.data.remarks
  );

  res.status(201).json(result);
}
