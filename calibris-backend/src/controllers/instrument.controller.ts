import { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "../db";

export async function listInstrumentTypes(_req: Request, res: Response) {
  const types = await prisma.instrumentType.findMany({ orderBy: { name: "asc" } });
  res.json(types);
}

const createInstrumentSchema = z.object({
  instrumentTypeId: z.string(),
  serialNumber: z.string().min(1),
  manufacturer: z.string().optional(),
  model: z.string().optional(),
  capacity: z.string().optional(),
  yearOfMake: z.number().int().optional(),
});

export async function registerInstrument(req: Request, res: Response) {
  const parsed = createInstrumentSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  const vendorId = req.auth!.sub;

  const duplicate = await prisma.instrument.findUnique({
    where: {
      instrumentTypeId_serialNumber: {
        instrumentTypeId: parsed.data.instrumentTypeId,
        serialNumber: parsed.data.serialNumber,
      },
    },
  });
  if (duplicate) {
    return res.status(409).json({ error: "An instrument with this type and serial number already exists" });
  }

  const instrument = await prisma.instrument.create({
    data: { ...parsed.data, vendorId },
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
