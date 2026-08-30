import "dotenv/config";
import path from "node:path";
import { defineConfig } from "prisma/config";

// Prisma 7 config entrypoint.
// On Railway / direct postgres, DATABASE_URL is standard.
// If DIRECT_URL is provided (e.g. Supabase port 5432 vs 6543 pooler), we prefer DIRECT_URL for migrations.
const dbUrl = process.env.DIRECT_URL || process.env.DATABASE_URL || "";

if (!dbUrl) {
  console.error(
    "❌ [Prisma Config Error]: Neither DIRECT_URL nor DATABASE_URL is set in environment variables!\n" +
    "👉 Please add DATABASE_URL in your Railway backend service Variables tab."
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
