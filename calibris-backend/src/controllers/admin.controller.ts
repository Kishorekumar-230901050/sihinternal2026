import { Request, Response } from "express";
import bcrypt from "bcryptjs";
import { z } from "zod";
import { prisma } from "../db";
import { transitionApplication } from "../services/status.service";
import { issueCertificateForApplication } from "../services/certificate.service";

const SALT_ROUNDS = 10;

export async function dashboard(_req: Request, res: Response) {
  const [statusCounts, instrumentCounts, totalGatcs, totalLmos] = await Promise.all([
    prisma.application.groupBy({ by: ["status"], _count: { _all: true } }),
    prisma.instrument.groupBy({ by: ["instrumentTypeId"], _count: { _all: true } }),
    prisma.gATC.count(),
    prisma.lMO.count(),
  ]);

  res.json({
    applicationsByStatus: statusCounts.map((s) => ({ status: s.status, count: s._count._all })),
    instrumentsByType: instrumentCounts.map((i) => ({ instrumentTypeId: i.instrumentTypeId, count: i._count._all })),
    totalGatcs,
    totalLmos,
  });
}

// --- LMO management ---------------------------------------------------

const createLmoSchema = z.object({
  fullName: z.string().min(2),
  email: z.string().email(),
  phone: z.string().min(8),
  password: z.string().min(8),
  employeeCode: z.string().min(2),
  departmentId: z.string().optional(),
  locationIds: z.array(z.string()).optional(),
});

export async function createLmo(req: Request, res: Response) {
  const parsed = createLmoSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  const { password, locationIds, ...rest } = parsed.data;

  const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
  const lmo = await prisma.lMO.create({ data: { ...rest, passwordHash } });

  if (locationIds?.length) {
    await prisma.lMOLocation.createMany({
      data: locationIds.map((locationId) => ({ lmoId: lmo.id, locationId })),
      skipDuplicates: true,
    });
  }

  res.status(201).json({ id: lmo.id, fullName: lmo.fullName, email: lmo.email, employeeCode: lmo.employeeCode });
}

export async function listLmos(_req: Request, res: Response) {
  const lmos = await prisma.lMO.findMany({
    select: { id: true, fullName: true, email: true, employeeCode: true, department: true, locations: { include: { location: true } } },
    orderBy: { fullName: "asc" },
  });
  res.json(lmos);
}

// --- GATC management -----------------------------------------------------

const createGatcSchema = z.object({
  name: z.string().min(2),
  addressLine: z.string(),
  latitude: z.number(),
  longitude: z.number(),
  locationId: z.string(),
  contactPhone: z.string().optional(),
  instrumentTypeIds: z.array(z.string()).min(1),
  dailyCapacity: z.number().int().positive().default(20),
});

export async function createGatc(req: Request, res: Response) {
  const parsed = createGatcSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  const { instrumentTypeIds, dailyCapacity, ...rest } = parsed.data;

  const gatc = await prisma.gATC.create({
    data: {
      ...rest,
      instrumentTypes: {
        create: instrumentTypeIds.map((instrumentTypeId) => ({ instrumentTypeId, dailyCapacity })),
      },
    },
    include: { instrumentTypes: true },
  });

  res.status(201).json(gatc);
}

// --- Queue review ----------------------------------------------------------

export async function listQueue(req: Request, res: Response) {
  const status = req.query.status as string | undefined;
  const applications = await prisma.application.findMany({
    where: status ? { status: status as never } : { status: { in: ["PAYMENT_COMPLETE", "LMO_ASSIGNED"] } },
    include: {
      vendor: { select: { fullName: true, businessName: true } },
      instrument: { include: { instrumentType: true } },
      gatc: { include: { location: true } },
      assignedLmo: { select: { id: true, fullName: true } },
    },
    orderBy: { createdAt: "asc" },
  });
  res.json(applications);
}

const assignLmoSchema = z.object({ lmoId: z.string() });

export async function assignLmo(req: Request, res: Response) {
  const parsed = assignLmoSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  const applicationId = req.params.applicationId;
  const adminId = req.auth!.sub;

  await prisma.application.update({ where: { id: applicationId }, data: { assignedLmoId: parsed.data.lmoId } });
  const updated = await transitionApplication(applicationId, "LMO_ASSIGNED", { type: "ADMIN", id: adminId }, `Assigned to LMO ${parsed.data.lmoId}`);

  await prisma.auditLog.create({
    data: { adminId, action: "ASSIGN_LMO", entityType: "Application", entityId: applicationId, metaJson: { lmoId: parsed.data.lmoId } },
  });

  res.json(updated);
}

/**
 * Manual fallback: generates the certificate PDF + QR for a PASSED
 * application. Normally unnecessary — the LMO's PASS submission already
 * auto-issues the certificate — but kept for applications passed before
 * that behavior existed, or if auto-issuance ever fails.
 */
export async function approveCertificate(req: Request, res: Response) {
  const applicationId = req.params.applicationId;
  const adminId = req.auth!.sub;

  const verifyBaseUrl = `${req.protocol}://${req.get("host")}/verify`;
  const updatedCert = await issueCertificateForApplication(applicationId, { type: "ADMIN", id: adminId }, verifyBaseUrl);

  await prisma.auditLog.create({
    data: { adminId, action: "APPROVE_CERTIFICATE", entityType: "Application", entityId: applicationId },
  });

  res.status(201).json(updatedCert);
}

export async function rejectApplication(req: Request, res: Response) {
  const applicationId = req.params.applicationId;
  const adminId = req.auth!.sub;
  const { reason } = req.body as { reason?: string };

  const updated = await transitionApplication(applicationId, "REJECTED", { type: "ADMIN", id: adminId }, reason);
  await prisma.auditLog.create({
    data: { adminId, action: "REJECT_APPLICATION", entityType: "Application", entityId: applicationId, metaJson: { reason } },
  });
  res.json(updated);
}

export async function listAuditLogs(_req: Request, res: Response) {
  const logs = await prisma.auditLog.findMany({
    include: { admin: { select: { fullName: true, email: true } } },
    orderBy: { createdAt: "desc" },
    take: 200,
  });
  res.json(logs);
}
