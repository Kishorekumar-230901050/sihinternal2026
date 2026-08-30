// server/migrations/run-recreate-devices.ts
// Script to run the devices table recreation migration
// WARNING: This will DELETE all existing device and tamper_logs data!

import "dotenv/config";
import { pool } from "../db";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import readline from "readline";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function askConfirmation(): Promise<boolean> {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  return new Promise((resolve) => {
    rl.question(
      "\n⚠️  WARNING: This will DELETE all existing device and tamper_logs data!\nDo you want to continue? (yes/no): ",
      (answer) => {
        rl.close();
        resolve(answer.toLowerCase() === "yes");
      }
    );
  });
}

async function main() {
  console.log("🚨 DESTRUCTIVE MIGRATION: Recreate devices table");
  console.log("This will:");
  console.log("  - DROP the existing devices table");
  console.log("  - DELETE all tamper_logs (due to foreign key cascade)");
  console.log("  - CREATE a new devices table with simplified schema");
  console.log("  - CREATE device_users table if it doesn't exist");

  const confirmed = await askConfirmation();

  if (!confirmed) {
    console.log("❌ Migration cancelled by user");
    await pool.end();
    process.exit(0);
  }

  console.log("\n🚀 Starting migration...");

  try {
    const migrationPath = path.join(__dirname, "002-recreate-devices-table.sql");
    const sql = fs.readFileSync(migrationPath, "utf-8");

    await pool.query(sql);

    console.log("\n✅ Migration completed successfully!");
    console.log("\n📋 New devices table schema:");
    console.log("  - device_id (SERIAL PRIMARY KEY)");
    console.log("  - user_id (INTEGER, FK to device_users)");
    console.log("  - device_type (TEXT)");
    console.log("  - purchase_date (TEXT, ISO8601)");
  } catch (error) {
    console.error("\n❌ Migration failed:", error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

main();
