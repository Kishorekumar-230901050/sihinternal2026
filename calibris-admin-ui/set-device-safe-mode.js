// Set Device 1 to safe_mode status for testing unlock button
import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function setDeviceMode() {
  try {
    await pool.query(`
      UPDATE devices
      SET status = 'safe_mode', location = 'Lab Testing', owner = 'Test User'
      WHERE device_id = 1
    `);

    const result = await pool.query('SELECT * FROM devices WHERE device_id = 1');
    console.log('✓ Device 1 updated to safe_mode:');
    console.log(JSON.stringify(result.rows[0], null, 2));

  } catch (err) {
    console.error('✗ Error:', err.message);
  } finally {
    await pool.end();
  }
}

setDeviceMode();
