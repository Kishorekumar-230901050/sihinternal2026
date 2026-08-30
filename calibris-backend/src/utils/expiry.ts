export type ExpiryStatus = "VALID" | "EXPIRING_SOON" | "EXPIRED";

const EXPIRING_SOON_DAYS = 30;

/** Classifies a certificate's validity window relative to now. */
export function classifyExpiry(validUntil: Date, now: Date = new Date()): ExpiryStatus {
  const daysLeft = Math.ceil((validUntil.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
  if (daysLeft < 0) return "EXPIRED";
  if (daysLeft <= EXPIRING_SOON_DAYS) return "EXPIRING_SOON";
  return "VALID";
}
