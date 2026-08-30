import { ApplicationStatus } from "@prisma/client";
import { prisma } from "../db";

/**
 * Explicit allow-list of legal state transitions for an Application.
 * Any transition not listed here is rejected. This is the single source
 * of truth for lifecycle rules — controllers must never mutate `status`
 * directly on the Application model.
 */
const ALLOWED_TRANSITIONS: Record<ApplicationStatus, ApplicationStatus[]> = {
  SUBMITTED: ["DOCUMENTS_PENDING", "CANCELLED"],
  DOCUMENTS_PENDING: ["DOCUMENTS_VERIFIED", "CANCELLED"],
  DOCUMENTS_VERIFIED: ["SLOT_BOOKED", "CANCELLED"],
  SLOT_BOOKED: ["PAYMENT_PENDING", "CANCELLED"],
  PAYMENT_PENDING: ["PAYMENT_COMPLETE", "CANCELLED"],
  PAYMENT_COMPLETE: ["LMO_ASSIGNED", "CANCELLED"],
  LMO_ASSIGNED: ["INSPECTION_IN_PROGRESS", "CANCELLED"],
  INSPECTION_IN_PROGRESS: ["INSPECTION_COMPLETE"],
  INSPECTION_COMPLETE: ["PASSED", "FAILED"],
  PASSED: ["CERTIFICATE_ISSUED"],
  FAILED: ["REJECTED"],
  CERTIFICATE_ISSUED: [],
  REJECTED: [],
  CANCELLED: [],
};

export class InvalidTransitionError extends Error {
  constructor(from: ApplicationStatus, to: ApplicationStatus) {
    super(`Illegal application status transition: ${from} -> ${to}`);
    this.name = "InvalidTransitionError";
  }
}

export function canTransition(from: ApplicationStatus, to: ApplicationStatus): boolean {
  return ALLOWED_TRANSITIONS[from]?.includes(to) ?? false;
}

interface TransitionActor {
  type: "USER" | "LMO" | "ADMIN" | "SYSTEM";
  id?: string;
}

/**
 * Applies a validated status transition to an Application in a single
 * transaction, writing an immutable ApplicationStatusHistory row.
 */
export async function transitionApplication(
  applicationId: string,
  toStatus: ApplicationStatus,
  actor: TransitionActor,
  note?: string
) {
  return prisma.$transaction(async (tx) => {
    const application = await tx.application.findUnique({
      where: { id: applicationId },
    });
    if (!application) {
      throw new Error(`Application ${applicationId} not found`);
    }

    if (!canTransition(application.status, toStatus)) {
      throw new InvalidTransitionError(application.status, toStatus);
    }

    const updated = await tx.application.update({
      where: { id: applicationId },
      data: { status: toStatus },
    });

    await tx.applicationStatusHistory.create({
      data: {
        applicationId,
        fromStatus: application.status,
        toStatus,
        changedByType: actor.type,
        changedById: actor.id,
        note,
      },
    });

    return updated;
  });
}
