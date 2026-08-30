// server/migrations/verify-schema.ts
// Script to verify the devices table schema

import "dotenv/config";
import { pool } from "../db";

async function verifySchema() {
  console.log("🔍 Verifying devices table schema...\n");

  try {
    const result = await pool.query(`
      SELECT column_name, data_type, character_maximum_length, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'devices'
      ORDER BY ordinal_position;
    `);

    console.log("📋 Devices table columns:");
    console.table(result.rows);

    // Check for city and state columns
    const hasCityColumn = result.rows.some(row => row.column_name === 'city');
    const hasStateColumn = result.rows.some(row => row.column_name === 'state');

    if (hasCityColumn && hasStateColumn) {
      console.log("\n✅ Migration verified: city and state columns exist!");
    } else {
      console.log("\n❌ Migration incomplete:");
      if (!hasCityColumn) console.log("  - city column is missing");
      if (!hasStateColumn) console.log("  - state column is missing");
    }
  } catch (error) {
    console.error("❌ Verification failed:", error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

verifySchema();
