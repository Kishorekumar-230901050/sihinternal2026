// server/migrations/run-migration.ts
// Script to run database migrations

import "dotenv/config";
import { pool } from "../db";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function runMigration(migrationFile: string) {
  console.log(`📦 Running migration: ${migrationFile}`);

  try {
    const migrationPath = path.join(__dirname, migrationFile);
    const sql = fs.readFileSync(migrationPath, "utf-8");

    await pool.query(sql);

    console.log(`✅ Migration ${migrationFile} completed successfully`);
  } catch (error) {
    console.error(`❌ Migration ${migrationFile} failed:`, error);
    throw error;
  }
}

async function main() {
  console.log("🚀 Starting database migrations...");

  try {
    // Run migrations in order
    await runMigration("001-add-city-state-to-devices.sql");

    console.log("\n✅ All migrations completed successfully!");
  } catch (error) {
    console.error("\n❌ Migration failed:", error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

main();
