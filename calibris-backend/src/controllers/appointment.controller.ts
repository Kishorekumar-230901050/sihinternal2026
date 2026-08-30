import { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "../db";
import { transitionApplication } from "../services/status.service";

const bookSlotSchema = z.object({
  applicationId: z.string(),
  gatcId: z.string(),
  slotDate: z.string(), // ISO date, e.g. "2026-09-05"
  slotStart: z.string(), // ISO datetime
  slotEnd: z.string(), // ISO datetime
});

/**
 * Books a slot for an application. Capacity is enforced by counting
 * existing appointments for the same GATC + instrument type + day inside
 * a transaction (serialized via a row lock on the GATCInstrumentType row)
 * so two vendors racing for the last slot can't both succeed.
 */
export async function bookAppointment(req: Request, res: Response) {
  const parsed = bookSlotSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  const { applicationId, gatcId, slotDate, slotStart, slotEnd } = parsed.data;
  const vendorId = req.auth!.sub;

  const application = await prisma.application.findFirst({
    where: { id: applicationId, vendorId },
    include: { instrument: true },
  });
  if (!application) return res.status(404).json({ error: "Application not found" });
  if (application.status !== "DOCUMENTS_VERIFIED") {
    return res.status(409).json({ error: `Cannot book a slot while application is in status ${application.status}` });
  }

  const mapping = await prisma.gATCInstrumentType.findUnique({
    where: { gatcId_instrumentTypeId: { gatcId, instrumentTypeId: application.instrument.instrumentTypeId } },
  });
  if (!mapping) return res.status(400).json({ error: "Selected GATC does not support this instrument type" });

  const dayStart = new Date(new Date(slotDate).setHours(0, 0, 0, 0));
  const dayEnd = new Date(new Date(slotDate).setHours(23, 59, 59, 999));

  try {
    const appointment = await prisma.$transaction(async (tx) => {
      // Lock the mapping row to serialize concurrent bookings against the same day's capacity.
      await tx.$queryRaw`SELECT id FROM gatc_instrument_types WHERE id = ${mapping.id} FOR UPDATE`;

      const bookedCount = await tx.appointment.count({
        where: {
          gatcId,
          slotDate: { gte: dayStart, lte: dayEnd },
          application: { instrumentId: { in: undefined }, instrument: { instrumentTypeId: application.instrument.instrumentTypeId } },
        },
      });

      if (bookedCount >= mapping.dailyCapacity) {
        throw new Error("SLOT_FULL");
      }

      const created = await tx.appointment.create({
        data: {
          applicationId,
          gatcId,
          slotDate: dayStart,
          slotStart: new Date(slotStart),
          slotEnd: new Date(slotEnd),
        },
      });

      await tx.application.update({ where: { id: applicationId }, data: { gatcId } });

      return created;
    });

    await transitionApplication(applicationId, "SLOT_BOOKED", { type: "USER", id: vendorId }, `Slot booked at GATC ${gatcId}`);

    res.status(201).json(appointment);
  } catch (err) {
    if (err instanceof Error && err.message === "SLOT_FULL") {
      return res.status(409).json({ error: "No capacity remaining for this GATC/day. Please pick another slot." });
    }
    throw err;
  }
}

export async function gatcAvailability(req: Request, res: Response) {
  const { gatcId, instrumentTypeId, slotDate } = req.query as Record<string, string>;
  if (!gatcId || !instrumentTypeId || !slotDate) {
    return res.status(400).json({ error: "gatcId, instrumentTypeId, slotDate are required" });
  }

  const mapping = await prisma.gATCInstrumentType.findUnique({
    where: { gatcId_instrumentTypeId: { gatcId, instrumentTypeId } },
  });
  if (!mapping) return res.status(404).json({ error: "GATC does not support this instrument type" });

  const dayStart = new Date(new Date(slotDate).setHours(0, 0, 0, 0));
  const dayEnd = new Date(new Date(slotDate).setHours(23, 59, 59, 999));

  const bookedCount = await prisma.appointment.count({
    where: {
      gatcId,
      slotDate: { gte: dayStart, lte: dayEnd },
      application: { instrument: { instrumentTypeId } },
    },
  });

  res.json({
    gatcId,
    instrumentTypeId,
    slotDate,
    dailyCapacity: mapping.dailyCapacity,
    booked: bookedCount,
    remaining: Math.max(0, mapping.dailyCapacity - bookedCount),
  });
}
