import "dotenv/config";
import path from "node:path";
import { defineConfig } from "prisma/config";

// Helper to check if a URL is a real postgres URL and not an unconfigured placeholder
function isValidPostgresUrl(url: string | undefined): boolean {
  if (!url) return false;
  const trimmed = url.trim();
  if (!trimmed.startsWith("postgresql://") && !trimmed.startsWith("postgres://")) {
    return false;
  }
  if (trimmed.includes("[PASSWORD]") || trimmed.includes("[HOST]")) {
    return false;
  }
  return true;
}

let dbUrl = "";
if (isValidPostgresUrl(process.env.DIRECT_URL)) {
  dbUrl = process.env.DIRECT_URL!.trim();
} else if (isValidPostgresUrl(process.env.DATABASE_URL)) {
  dbUrl = process.env.DATABASE_URL!.trim();
} else {
  // Fallback: pick whichever is non-empty or empty string
  dbUrl = (process.env.DATABASE_URL || process.env.DIRECT_URL || "").trim();
}

if (!isValidPostgresUrl(dbUrl)) {
  console.error(
    "\n❌ [Prisma Config Error] Invalid or missing database connection string!\n" +
    `DATABASE_URL value is: "${process.env.DATABASE_URL || "NOT SET"}"\n` +
    `DIRECT_URL value is: "${process.env.DIRECT_URL || "NOT SET"}"\n` +
    "👉 Fix: In Railway Variables, set DATABASE_URL to ${{Postgres.DATABASE_URL}} and delete DIRECT_URL.\n"
  );
}

export default defineConfig({
  schema: path.join("prisma", "schema.prisma"),
  migrations: {
    path: path.join("prisma", "migrations"),
  },
  datasource: {
    url: dbUrl,
  },
});
