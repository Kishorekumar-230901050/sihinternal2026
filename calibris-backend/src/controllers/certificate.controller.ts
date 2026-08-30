import { Request, Response } from "express";
import { prisma } from "../db";

/**
 * Public endpoint reached by scanning the certificate QR code. Intentionally
 * excludes vendor contact details (phone, address, email) — only
 * information relevant to verifying instrument compliance is exposed.
 */
export async function verifyPublic(req: Request, res: Response) {
  const certificate = await prisma.certificate.findUnique({
    where: { qrToken: req.params.qrToken },
    include: {
      application: {
        include: {
          instrument: { include: { instrumentType: true } },
          gatc: { select: { name: true, location: { select: { district: true, state: true } } } },
        },
      },
    },
  });

  if (!certificate) return res.status(404).json({ error: "Certificate not found" });

  const isValid = certificate.validUntil > new Date();

  res.json({
    certificateNo: certificate.certificateNo,
    status: isValid ? "VALID" : "EXPIRED",
    issuedAt: certificate.issuedAt,
    validUntil: certificate.validUntil,
    instrumentType: certificate.application.instrument.instrumentType.name,
    serialNumberMasked: maskSerial(certificate.application.instrument.serialNumber),
    testCentre: certificate.application.gatc?.name ?? null,
    district: certificate.application.gatc?.location.district ?? null,
    state: certificate.application.gatc?.location.state ?? null,
  });
}

function maskSerial(serial: string): string {
  if (serial.length <= 4) return serial;
  return `${"*".repeat(serial.length - 4)}${serial.slice(-4)}`;
}

export async function getMyCertificate(req: Request, res: Response) {
  const vendorId = req.auth!.sub;
  const certificate = await prisma.certificate.findFirst({
    where: { application: { id: req.params.applicationId, vendorId } },
    include: { versions: { orderBy: { versionNumber: "desc" } } },
  });
  if (!certificate) return res.status(404).json({ error: "No certificate issued for this application" });
  res.json(certificate);
}
