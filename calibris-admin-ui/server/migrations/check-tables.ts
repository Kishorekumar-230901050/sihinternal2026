// server/migrations/check-tables.ts
// Script to check both devices and tamper_logs table schemas

import "dotenv/config";
import { pool } from "../db";

async function checkTables() {
  console.log("🔍 Checking database schema...\n");

  try {
    // Check devices table
    console.log("📋 DEVICES TABLE:");
    const devicesResult = await pool.query(`
      SELECT column_name, data_type, character_maximum_length, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'devices'
      ORDER BY ordinal_position;
    `);
    console.table(devicesResult.rows);

    // Check tamper_logs table
    console.log("\n📋 TAMPER_LOGS TABLE:");
    const tamperResult = await pool.query(`
      SELECT column_name, data_type, character_maximum_length, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'tamper_logs'
      ORDER BY ordinal_position;
    `);
    console.table(tamperResult.rows);

  } catch (error) {
    console.error("❌ Error:", error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

checkTables();
