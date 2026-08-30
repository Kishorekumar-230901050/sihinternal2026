import "dotenv/config";
import { Pool } from "pg";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "@prisma/client";

// Prisma 7 requires an explicit driver adapter rather than relying on the
// implicit query engine connection. We reuse a single pg Pool across the
// process (important for serverless/dev hot-reload) to avoid exhausting
// Supabase's pooled connection limit.

declare global {
  // eslint-disable-next-line no-var
  var __calibrisPgPool: Pool | undefined;
  // eslint-disable-next-line no-var
  var __calibrisPrisma: PrismaClient | undefined;
}

function createPool(): Pool {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error(
      "DATABASE_URL is not set. Copy .env.example to .env and fill in your Supabase pooled connection string (port 6543)."
    );
  }
  return new Pool({ connectionString });
}

const pool = global.__calibrisPgPool ?? createPool();
if (process.env.NODE_ENV !== "production") {
  global.__calibrisPgPool = pool;
}

const adapter = new PrismaPg(pool);

export const prisma =
  global.__calibrisPrisma ??
  new PrismaClient({
    adapter,
    log: process.env.NODE_ENV === "production" ? ["error", "warn"] : ["error", "warn"],
  });

if (process.env.NODE_ENV !== "production") {
  global.__calibrisPrisma = prisma;
}

export async function disconnectDb(): Promise<void> {
  await prisma.$disconnect();
  await pool.end();
}
