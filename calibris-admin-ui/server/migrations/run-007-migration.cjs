// Migration script to add officer details columns to unlock_commands
require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function migrate() {
  console.log('Starting migration 007 - Add officer details to unlock_commands...');

  try {
    // Add officer_name column
    await pool.query(`ALTER TABLE unlock_commands ADD COLUMN IF NOT EXISTS officer_name TEXT`);
    console.log('✅ Added officer_name column');

    // Add officer_email column
    await pool.query(`ALTER TABLE unlock_commands ADD COLUMN IF NOT EXISTS officer_email TEXT`);
    console.log('✅ Added officer_email column');

    // Add officer_role column
    await pool.query(`ALTER TABLE unlock_commands ADD COLUMN IF NOT EXISTS officer_role TEXT`);
    console.log('✅ Added officer_role column');

    // Add index
    await pool.query(`CREATE INDEX IF NOT EXISTS idx_unlock_commands_officer ON unlock_commands(officer_email)`);
    console.log('✅ Added index on officer_email');

    // Check current table structure
    const result = await pool.query(`
      SELECT column_name, data_type
      FROM information_schema.columns
      WHERE table_name = 'unlock_commands'
      ORDER BY ordinal_position
    `);
    console.log('\n📋 unlock_commands table structure:');
    console.table(result.rows);

    console.log('\n✅ Migration 007 complete!');
  } catch (err) {
    console.error('❌ Migration error:', err);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

migrate();
