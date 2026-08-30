import PDFDocument from "pdfkit";
import QRCode from "qrcode";
import { PassThrough } from "node:stream";

async function streamToBuffer(doc: PDFKit.PDFDocument): Promise<Buffer> {
  const pass = new PassThrough();
  const chunks: Buffer[] = [];
  doc.pipe(pass);
  pass.on("data", (chunk) => chunks.push(chunk));
  const done = new Promise<Buffer>((resolve, reject) => {
    pass.on("end", () => resolve(Buffer.concat(chunks)));
    pass.on("error", reject);
  });
  doc.end();
  return done;
}

export interface CertificatePdfInput {
  certificateNo: string;
  qrToken: string;
  verifyBaseUrl: string; // e.g. http://localhost:3000/verify
  vendorName: string;
  businessName?: string | null;
  instrumentTypeName: string;
  serialNumber: string;
  gatcName: string;
  lmoName: string;
  issuedAt: Date;
  validUntil: Date;
  resultRemarks?: string | null;
}

export async function generateCertificatePdf(input: CertificatePdfInput): Promise<Buffer> {
  const doc = new PDFDocument({ size: "A4", margin: 50 });

  const verifyUrl = `${input.verifyBaseUrl}/${input.qrToken}`;
  const qrDataUrl = await QRCode.toDataURL(verifyUrl, { margin: 1 });
  const qrImage = Buffer.from(qrDataUrl.split(",")[1], "base64");

  doc
    .fontSize(18)
    .fillColor("#0B3D91")
    .text("CALIBRIS — Legal Metrology Verification Certificate", { align: "center" })
    .moveDown(1);

  doc.fontSize(11).fillColor("#000000");
  doc.text(`Certificate No: ${input.certificateNo}`);
  doc.text(`Issued: ${input.issuedAt.toDateString()}`);
  doc.text(`Valid Until: ${input.validUntil.toDateString()}`);
  doc.moveDown(1);

  doc.fontSize(13).fillColor("#0B3D91").text("Instrument Owner");
  doc.fontSize(11).fillColor("#000000");
  doc.text(`Name: ${input.vendorName}`);
  if (input.businessName) doc.text(`Business: ${input.businessName}`);
  doc.moveDown(0.5);

  doc.fontSize(13).fillColor("#0B3D91").text("Instrument Details");
  doc.fontSize(11).fillColor("#000000");
  doc.text(`Type: ${input.instrumentTypeName}`);
  doc.text(`Serial Number: ${input.serialNumber}`);
  doc.moveDown(0.5);

  doc.fontSize(13).fillColor("#0B3D91").text("Verification Details");
  doc.fontSize(11).fillColor("#000000");
  doc.text(`Test Centre: ${input.gatcName}`);
  doc.text(`Legal Metrology Officer: ${input.lmoName}`);
  if (input.resultRemarks) doc.text(`Remarks: ${input.resultRemarks}`);
  doc.moveDown(1.5);

  doc.image(qrImage, doc.page.width - 170, doc.y, { width: 110 });
  doc.fontSize(9).fillColor("#555555").text("Scan to verify publicly", doc.page.width - 170, doc.y + 5, {
    width: 110,
    align: "center",
  });

  return streamToBuffer(doc);
}

export interface ReceiptPdfInput {
  orderRef: string;
  transactionRef: string;
  amountInPaise: number;
  vendorName: string;
  paidAt: Date;
}

export async function generateReceiptPdf(input: ReceiptPdfInput): Promise<Buffer> {
  const doc = new PDFDocument({ size: "A5", margin: 40 });

  doc.fontSize(16).fillColor("#0B3D91").text("CALIBRIS — Payment Receipt", { align: "center" }).moveDown(1);
  doc.fontSize(11).fillColor("#000000");
  doc.text(`Order Ref: ${input.orderRef}`);
  doc.text(`Transaction Ref: ${input.transactionRef}`);
  doc.text(`Paid By: ${input.vendorName}`);
  doc.text(`Amount: ₹${(input.amountInPaise / 100).toFixed(2)}`);
  doc.text(`Date: ${input.paidAt.toString()}`);

  return streamToBuffer(doc);
}
