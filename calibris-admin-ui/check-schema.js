// Check the actual schema of devices table
import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function checkSchema() {
  try {
    const result = await pool.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'devices'
      ORDER BY ordinal_position
    `);

    console.log('✓ Devices table columns:');
    result.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} ${col.is_nullable === 'NO' ? '(required)' : '(optional)'}`);
    });

  } catch (err) {
    console.error('✗ Error:', err.message);
  } finally {
    await pool.end();
  }
}

checkSchema();
