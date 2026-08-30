import "dotenv/config";
import path from "node:path";
import { defineConfig, env } from "prisma/config";

// Prisma 7 config entrypoint. schema.prisma no longer holds connection
// URLs at all — the CLI (migrate/db push/studio) reads the connection
// string from `datasource.url` below, while the running app connects via
// the driver adapter constructed in src/db.ts (using DATABASE_URL, the
// pooled connection).
//
// We point the CLI at DIRECT_URL (port 5432, non-pooled) rather than
// DATABASE_URL (port 6543, pgbouncer) because DDL operations like
// `db push`/`migrate dev` are unreliable over a transaction pooler.
export default defineConfig({
  schema: path.join("prisma", "schema.prisma"),
  migrations: {
    path: path.join("prisma", "migrations"),
  },
  datasource: {
    url: env("DIRECT_URL"),
  },
});
