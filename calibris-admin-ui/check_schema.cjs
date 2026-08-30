const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function checkSchema() {
  try {
    const result = await pool.query(
      `SELECT column_name, data_type
       FROM information_schema.columns
       WHERE table_name = 'tamper_logs'
       ORDER BY ordinal_position`
    );

    console.log('\n📋 TAMPER_LOGS TABLE SCHEMA:');
    console.log('═══════════════════════════════════════');
    result.rows.forEach(row => {
      console.log(`  ${row.column_name.padEnd(20)} ${row.data_type}`);
    });

    // Check for sample data with lat/lon
    const sampleData = await pool.query(
      `SELECT id, device_id, tamper_type, latitude, longitude, event_time
       FROM tamper_logs
       WHERE latitude IS NOT NULL AND longitude IS NOT NULL
       LIMIT 3`
    );

    console.log('\n📍 SAMPLE TAMPER LOGS WITH COORDINATES:');
    console.log('═══════════════════════════════════════');
    sampleData.rows.forEach(row => {
      console.log(`  ID ${row.id}: Device ${row.device_id} - ${row.tamper_type}`);
      console.log(`    Lat/Lon: ${row.latitude}, ${row.longitude}`);
      console.log(`    Time: ${row.event_time}`);
    });

    await pool.end();
  } catch (err) {
    console.error('❌ Error:', err.message);
    process.exit(1);
  }
}

checkSchema();
