// Quick test to check database connection and devices
import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function test() {
  try {
    // Test connection
    const result = await pool.query('SELECT NOW()');
    console.log('✓ Database connected:', result.rows[0]);

    // Check devices table
    const devices = await pool.query('SELECT * FROM devices');
    console.log('✓ Devices found:', devices.rows.length);
    console.log('Devices:', JSON.stringify(devices.rows, null, 2));

    // Check if unlock_commands table exists
    const tables = await pool.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = 'unlock_commands'
    `);
    console.log('✓ unlock_commands table exists:', tables.rows.length > 0);

  } catch (err) {
    console.error('✗ Error:', err.message);
    console.error('Stack:', err.stack);
  } finally {
    await pool.end();
  }
}

test();
