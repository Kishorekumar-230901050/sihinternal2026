import crypto from "node:crypto";
import { PaymentStatus } from "@prisma/client";
import { prisma } from "../db";
import { transitionApplication } from "./status.service";

/**
 * Mock payment gateway. Mirrors the two-phase Razorpay flow (create order,
 * then verify a signed callback) so the frontend integration code and the
 * eventual swap to a live Razorpay key are close to drop-in.
 *
 * Swap plan for production: replace `createMockOrder` with a call to
 * `razorpay.orders.create(...)` and replace `verifyMockCallback`'s HMAC
 * check with Razorpay's documented signature verification
 * (order_id + "|" + payment_id, signed with the key secret).
 */

const MOCK_KEY_SECRET = process.env.JWT_SECRET ?? "mock-secret";

export interface MockOrder {
  orderRef: string;
  amountInPaise: number;
  currency: "INR";
}

export async function createMockOrder(applicationId: string, amountInPaise: number): Promise<MockOrder> {
  const orderRef = `order_mock_${crypto.randomBytes(10).toString("hex")}`;

  await prisma.payment.create({
    data: {
      applicationId,
      amountInPaise,
      status: PaymentStatus.PENDING,
      provider: "MOCK_RAZORPAY",
      orderRef,
    },
  });

  await transitionApplication(applicationId, "PAYMENT_PENDING", { type: "SYSTEM" }, "Order created");

  return { orderRef, amountInPaise, currency: "INR" };
}

function signPayload(orderRef: string, transactionRef: string): string {
  return crypto
    .createHmac("sha256", MOCK_KEY_SECRET)
    .update(`${orderRef}|${transactionRef}`)
    .digest("hex");
}

export function buildMockCallback(orderRef: string) {
  const transactionRef = `pay_mock_${crypto.randomBytes(10).toString("hex")}`;
  const signature = signPayload(orderRef, transactionRef);
  return { orderRef, transactionRef, signature };
}

export async function verifyMockCallback(params: {
  orderRef: string;
  transactionRef: string;
  signature: string;
}): Promise<{ success: boolean; applicationId?: string }> {
  const expected = signPayload(params.orderRef, params.transactionRef);
  const valid =
    expected.length === params.signature.length &&
    crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(params.signature));

  const payment = await prisma.payment.findUnique({ where: { orderRef: params.orderRef } });
  if (!payment) return { success: false };

  if (!valid) {
    await prisma.payment.update({
      where: { orderRef: params.orderRef },
      data: { status: PaymentStatus.FAILED, transactionRef: params.transactionRef },
    });
    return { success: false, applicationId: payment.applicationId };
  }

  await prisma.payment.update({
    where: { orderRef: params.orderRef },
    data: { status: PaymentStatus.SUCCESS, transactionRef: params.transactionRef },
  });

  await transitionApplication(
    payment.applicationId,
    "PAYMENT_COMPLETE",
    { type: "SYSTEM" },
    `Mock payment ${params.transactionRef} verified`
  );

  // Auto-assign an LMO so the application reaches an officer's queue
  // immediately, without requiring a separate admin action.
  const lmo = await prisma.lMO.findFirst({ orderBy: { createdAt: "asc" } });
  if (lmo) {
    await prisma.application.update({
      where: { id: payment.applicationId },
      data: { assignedLmoId: lmo.id },
    });
    await transitionApplication(
      payment.applicationId,
      "LMO_ASSIGNED",
      { type: "SYSTEM" },
      `Auto-assigned to LMO ${lmo.fullName}`
    );
  }

  return { success: true, applicationId: payment.applicationId };
}
