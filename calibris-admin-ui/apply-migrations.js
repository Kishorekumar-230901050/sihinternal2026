// Apply database migrations
import pg from 'pg';
import dotenv from 'dotenv';
import fs from 'fs';

dotenv.config();

const { Pool } = pg;
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function applyMigrations() {
  try {
    console.log('📦 Starting migrations...\n');

    // Migration 1: Add missing device columns
    console.log('1️⃣  Applying migration: 005-add-missing-device-columns.sql');
    const migration1 = fs.readFileSync('server/migrations/005-add-missing-device-columns.sql', 'utf-8');
    await pool.query(migration1);
    console.log('✓ Migration 005 applied successfully\n');

    // Migration 2: Add unlock_commands table
    console.log('2️⃣  Applying migration: 004_add_unlock_commands.sql');
    const migration2 = fs.readFileSync('server/migrations/004_add_unlock_commands.sql', 'utf-8');
    await pool.query(migration2);
    console.log('✓ Migration 004 applied successfully\n');

    // Verify devices table structure
    console.log('✓ Verifying devices table...');
    const result = await pool.query(`
      SELECT column_name, data_type
      FROM information_schema.columns
      WHERE table_name = 'devices'
      ORDER BY ordinal_position
    `);
    console.log('  Columns:', result.rows.map(r => r.column_name).join(', '));

    // Verify unlock_commands table exists
    const tables = await pool.query(`
      SELECT table_name FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = 'unlock_commands'
    `);
    console.log('  unlock_commands table exists:', tables.rows.length > 0);

    // Check Device 1
    const device = await pool.query('SELECT * FROM devices WHERE device_id = 1');
    console.log('\n📱 Device 1:');
    console.log(JSON.stringify(device.rows[0], null, 2));

    console.log('\n✅ All migrations applied successfully!');

  } catch (err) {
    console.error('❌ Migration error:', err.message);
    console.error(err.stack);
  } finally {
    await pool.end();
  }
}

applyMigrations();
