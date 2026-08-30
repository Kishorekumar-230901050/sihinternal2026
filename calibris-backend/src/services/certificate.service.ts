import { prisma } from "../db";
import { transitionApplication } from "./status.service";
import { generateCertificatePdf } from "./pdf.service";
import { uploadFile } from "./storage.service";

interface Actor {
  type: "USER" | "LMO" | "ADMIN" | "SYSTEM";
  id?: string;
}

/**
 * Generates and stores the certificate PDF + QR for a PASSED application,
 * then transitions it to CERTIFICATE_ISSUED. Shared by the admin
 * manual-approval route and the automatic issuance that happens the
 * moment an LMO submits a PASS result — no separate department-approval
 * step is required.
 */
export async function issueCertificateForApplication(
  applicationId: string,
  actor: Actor,
  verifyBaseUrl: string
) {
  const application = await prisma.application.findUnique({
    where: { id: applicationId },
    include: {
      vendor: true,
      instrument: { include: { instrumentType: true } },
      gatc: true,
      assignedLmo: true,
      inspection: { include: { result: true } },
    },
  });
  if (!application) throw new Error("Application not found");
  if (application.status !== "PASSED") {
    throw new Error(`Application must be in PASSED status, currently ${application.status}`);
  }

  const certificateNo = `CAL-${new Date().getFullYear()}-${application.id.slice(-8).toUpperCase()}`;
  const issuedAt = new Date();
  const validUntil = new Date(issuedAt);
  validUntil.setFullYear(validUntil.getFullYear() + 1);

  const certificate = await prisma.certificate.create({
    data: { applicationId, certificateNo, issuedAt, validUntil },
  });

  const pdfBuffer = await generateCertificatePdf({
    certificateNo: certificate.certificateNo,
    qrToken: certificate.qrToken,
    verifyBaseUrl,
    vendorName: application.vendor.fullName,
    businessName: application.vendor.businessName,
    instrumentTypeName: application.instrument.instrumentType.name,
    serialNumber: application.instrument.serialNumber,
    gatcName: application.gatc?.name ?? "N/A",
    lmoName: application.assignedLmo?.fullName ?? "N/A",
    issuedAt,
    validUntil,
    resultRemarks: application.inspection?.result?.remarks,
  });

  const { url } = await uploadFile(pdfBuffer, `certificate-${certificate.certificateNo}.pdf`, "application/pdf");

  const updatedCert = await prisma.certificate.update({
    where: { id: certificate.id },
    data: {
      pdfUrl: url,
      versions: {
        create: {
          versionNumber: 1,
          snapshotJson: {
            certificateNo: certificate.certificateNo,
            vendorName: application.vendor.fullName,
            instrumentType: application.instrument.instrumentType.name,
            serialNumber: application.instrument.serialNumber,
            issuedAt,
            validUntil,
          },
          pdfUrl: url,
        },
      },
    },
  });

  await transitionApplication(applicationId, "CERTIFICATE_ISSUED", actor, "Certificate auto-issued on PASS");

  return updatedCert;
}
