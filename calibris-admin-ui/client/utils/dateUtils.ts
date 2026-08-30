// Utility functions for date/time formatting

export function getRelativeTime(timestamp: string | null | undefined): string {
  if (!timestamp) return "Never";

  const now = new Date().getTime();
  const then = new Date(timestamp).getTime();
  const diffMs = now - then;

  if (diffMs < 0) return "Just now";

  const diffSeconds = Math.floor(diffMs / 1000);
  const diffMinutes = Math.floor(diffSeconds / 60);
  const diffHours = Math.floor(diffMinutes / 60);
  const diffDays = Math.floor(diffHours / 24);

  if (diffSeconds < 60) {
    return "Just now";
  } else if (diffMinutes < 60) {
    return `${diffMinutes} minute${diffMinutes !== 1 ? 's' : ''} ago`;
  } else if (diffHours < 24) {
    return `${diffHours} hour${diffHours !== 1 ? 's' : ''} ago`;
  } else if (diffDays < 30) {
    return `${diffDays} day${diffDays !== 1 ? 's' : ''} ago`;
  } else {
    return new Date(timestamp).toLocaleDateString();
  }
}

export function formatTimestamp(ts?: string | null): string {
  if (!ts) return "—";

  // If already looks like "YYYY-MM-DD HH:MM:SS" return as-is
  if (/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/.test(ts)) return ts;

  const d = new Date(ts);
  if (Number.isNaN(d.getTime())) {
    // fallback: return original string so nothing is lost
    return ts;
  }

  const pad = (n: number) => String(n).padStart(2, "0");
  const YYYY = d.getFullYear();
  const MM = pad(d.getMonth() + 1);
  const DD = pad(d.getDate());
  const hh = pad(d.getHours());
  const mm = pad(d.getMinutes());
  const ss = pad(d.getSeconds());

  return `${YYYY}-${MM}-${DD} ${hh}:${mm}:${ss}`;
}
