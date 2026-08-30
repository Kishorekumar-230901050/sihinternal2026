// Quick script to fix device 1 status in database
import { Pool } from 'pg';
import * as dotenv from 'dotenv';

dotenv.config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

async function fixDeviceStatus() {
  try {
    console.log('🔧 Updating device 1 status to safe_mode...');

    const result = await pool.query(
      `UPDATE devices
       SET status = 'safe_mode', last_update = NOW()
       WHERE device_id = 1
       RETURNING *`
    );

    console.log('✅ Device status updated:', result.rows[0]);

    await pool.end();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    await pool.end();
    process.exit(1);
  }
}

fixDeviceStatus();
