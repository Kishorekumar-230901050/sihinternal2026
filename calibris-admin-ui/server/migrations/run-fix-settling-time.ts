// server/migrations/run-fix-settling-time.ts
// Fix settling_time column type to accept decimals

import "dotenv/config";
import { pool } from "../db";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function fixSettlingTime() {
  console.log("🔧 Fixing settling_time column type...\n");

  try {
    const migrationPath = path.join(__dirname, "003-fix-settling-time-type.sql");
    const sql = fs.readFileSync(migrationPath, "utf-8");

    await pool.query(sql);

    console.log("✅ Migration completed successfully!");
    console.log("   settling_time column now accepts decimals (NUMERIC type)");

  } catch (error) {
    console.error("❌ Migration failed:", error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

fixSettlingTime();
