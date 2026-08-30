import { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "../db";
import { createMockOrder, buildMockCallback, verifyMockCallback } from "../services/payment.service";
import { generateReceiptPdf } from "../services/pdf.service";
import { uploadFile } from "../services/storage.service";

const createOrderSchema = z.object({ applicationId: z.string() });

export async function createOrder(req: Request, res: Response) {
  const parsed = createOrderSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  const vendorId = req.auth!.sub;

  const application = await prisma.application.findFirst({
    where: { id: parsed.data.applicationId, vendorId },
    include: { instrument: { include: { instrumentType: true } } },
  });
  if (!application) return res.status(404).json({ error: "Application not found" });
  if (application.status !== "SLOT_BOOKED") {
    return res.status(409).json({ error: `Cannot create a payment order while application is in status ${application.status}` });
  }

  const order = await createMockOrder(application.id, application.instrument.instrumentType.feeInPaise);
  res.status(201).json(order);
}

/** Simulates the client-side Razorpay checkout success, i.e. what the
 *  Flutter app would receive back from the SDK after a successful mock
 *  payment. In a real integration this endpoint is replaced by whatever
 *  the client actually posts back to us; the signature check stays. */
export async function simulateCheckout(req: Request, res: Response) {
  const { orderRef } = req.body as { orderRef?: string };
  if (!orderRef) return res.status(400).json({ error: "orderRef is required" });
  const callback = buildMockCallback(orderRef);
  res.json(callback);
}

const verifySchema = z.object({
  orderRef: z.string(),
  transactionRef: z.string(),
  signature: z.string(),
});

export async function verifyPayment(req: Request, res: Response) {
  const parsed = verifySchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

  const result = await verifyMockCallback(parsed.data);
  if (!result.success) return res.status(402).json({ error: "Payment verification failed" });

  res.json({ verified: true, applicationId: result.applicationId });
}

export async function getReceipt(req: Request, res: Response) {
  const payment = await prisma.payment.findUnique({
    where: { orderRef: req.params.orderRef },
    include: { application: { include: { vendor: true } } },
  });
  if (!payment || payment.status !== "SUCCESS") {
    return res.status(404).json({ error: "No successful payment found for this order" });
  }

  const pdfBuffer = await generateReceiptPdf({
    orderRef: payment.orderRef,
    transactionRef: payment.transactionRef ?? "N/A",
    amountInPaise: payment.amountInPaise,
    vendorName: payment.application.vendor.fullName,
    paidAt: payment.updatedAt,
  });

  const { url } = await uploadFile(pdfBuffer, `receipt-${payment.orderRef}.pdf`, "application/pdf");
  res.json({ url });
}
