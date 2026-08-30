import { pool } from "../db";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function runMigration() {
  try {
    console.log("Running migration: 004-add-last-seen.sql");

    const sql = fs.readFileSync(
      path.join(__dirname, "004-add-last-seen.sql"),
      "utf8"
    );

    await pool.query(sql);

    console.log("✅ Migration completed successfully!");
    console.log("   - Added last_seen column to devices table");
    console.log("   - Created index on last_seen");
    console.log("   - Updated existing devices with current timestamp");

    // Verify the column was added
    const result = await pool.query(`
      SELECT column_name, data_type
      FROM information_schema.columns
      WHERE table_name = 'devices' AND column_name = 'last_seen'
    `);

    if (result.rows.length > 0) {
      console.log("\n✓ Verified: last_seen column exists");
      console.log(`  Type: ${result.rows[0].data_type}`);
    }

    process.exit(0);
  } catch (err) {
    console.error("❌ Migration failed:", err);
    process.exit(1);
  }
}

runMigration();
