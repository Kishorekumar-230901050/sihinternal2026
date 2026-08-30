import { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "../db";
import { classifyExpiry } from "../utils/expiry";

export async function listInstrumentTypes(_req: Request, res: Response) {
  let types = await prisma.instrumentType.findMany({ orderBy: { name: "asc" } });
  if (types.length === 0) {
    // Seed standard instrument types if table is empty
    types = await prisma.$transaction([
      prisma.instrumentType.create({
        data: {
          code: "EWS",
          name: "Electronic Weighing Scale",
          category: "Non-Automatic",
          feeInPaise: 50000,
          validityMonths: 12,
        },
      }),
      prisma.instrumentType.create({
        data: {
          code: "WB",
          name: "Weighbridge (Heavy Vehicle)",
          category: "Heavy Duty",
          feeInPaise: 150000,
          validityMonths: 12,
        },
      }),
      prisma.instrumentType.create({
        data: {
          code: "FDS",
          name: "Fuel Dispensing Pump",
          category: "Flow Meter",
          feeInPaise: 75000,
          validityMonths: 12,
        },
      }),
    ]);
  }
  res.json(types);
}

const createInstrumentSchema = z.object({
  instrumentTypeId: z.string().optional(),
  type: z.string().optional(),
  serialNumber: z.string().min(1),
  manufacturer: z.string().optional(),
  model: z.string().optional(),
  modelNumber: z.string().optional(),
  capacity: z.string().optional(),
  yearOfMake: z.number().int().optional(),
  uniqueId: z.string().optional(),
  address: z.string().optional(),
});

export async function registerInstrument(req: Request, res: Response) {
  const parsed = createInstrumentSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  const vendorId = req.auth!.sub;

  let instrumentTypeId = parsed.data.instrumentTypeId;

  // Resolve or create default instrument type if needed
  let instrumentType = instrumentTypeId
    ? await prisma.instrumentType.findUnique({ where: { id: instrumentTypeId } })
    : null;

  if (!instrumentType) {
    instrumentType = await prisma.instrumentType.findFirst();
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
  }

  const model = parsed.data.model || parsed.data.modelNumber || "Standard Model";
  const manufacturer = parsed.data.manufacturer || "Standard Manufacturer";
  const capacity = parsed.data.capacity || "30 kg";
  const serialNumber = parsed.data.serialNumber;

  // Check if instrument already registered
  const existing = await prisma.instrument.findUnique({
    where: {
      instrumentTypeId_serialNumber: {
        instrumentTypeId: instrumentType.id,
        serialNumber,
      },
    },
    include: { instrumentType: true },
  });

  if (existing) {
    // If owned by this vendor, return existing instrument smoothly
    if (existing.vendorId === vendorId) {
      return res.status(200).json(existing);
    }
    // Update ownership if re-registering in demo
    const updated = await prisma.instrument.update({
      where: { id: existing.id },
      data: {
        vendorId,
        model,
        manufacturer,
        capacity,
      },
      include: { instrumentType: true },
    });
    return res.status(200).json(updated);
  }

  const instrument = await prisma.instrument.create({
    data: {
      vendorId,
      instrumentTypeId: instrumentType.id,
      serialNumber,
      manufacturer,
      model,
      capacity,
      yearOfMake: parsed.data.yearOfMake ?? new Date().getFullYear(),
    },
    include: { instrumentType: true },
  });

  res.status(201).json(instrument);
}

export async function listMyInstruments(req: Request, res: Response) {
  const vendorId = req.auth!.sub;
  const instruments = await prisma.instrument.findMany({
    where: { vendorId },
    include: { instrumentType: true },
    orderBy: { createdAt: "desc" },
  });
  res.json(instruments);
}

/** Owner dashboard: instrument counts, application pipeline, expiry summary. */
export async function vendorDashboard(req: Request, res: Response) {
  const vendorId = req.auth!.sub;

  const [instrumentCount, applications] = await Promise.all([
    prisma.instrument.count({ where: { vendorId } }),
    prisma.application.findMany({
      where: { vendorId },
      select: { status: true, certificate: { select: { validUntil: true } } },
    }),
  ]);

  const pendingStatuses = new Set([
    "SUBMITTED",
    "DOCUMENTS_PENDING",
    "DOCUMENTS_VERIFIED",
    "SLOT_BOOKED",
    "PAYMENT_PENDING",
    "PAYMENT_COMPLETE",
    "LMO_ASSIGNED",
    "INSPECTION_IN_PROGRESS",
    "INSPECTION_COMPLETE",
  ]);

  let pendingApplications = 0;
  let verified = 0;
  let expiringSoon = 0;
  let expired = 0;

  for (const app of applications) {
    if (pendingStatuses.has(app.status)) pendingApplications++;
    if (app.status === "CERTIFICATE_ISSUED" && app.certificate) {
      verified++;
      const status = classifyExpiry(app.certificate.validUntil);
      if (status === "EXPIRING_SOON") expiringSoon++;
      if (status === "EXPIRED") expired++;
    }
  }

  res.json({
    myInstruments: instrumentCount,
    pendingApplications,
    verified,
    expiringSoon,
    expired,
  });
}
