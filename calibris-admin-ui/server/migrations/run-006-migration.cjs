// Migration script to add status and last_login columns to users_meta
require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function migrate() {
  console.log('Starting migration...');

  try {
    // Add status column
    await pool.query(`ALTER TABLE users_meta ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active'`);
    console.log('✅ Added status column');

    // Add last_login column
    await pool.query(`ALTER TABLE users_meta ADD COLUMN IF NOT EXISTS last_login TIMESTAMP`);
    console.log('✅ Added last_login column');

    // Check current users
    const result = await pool.query('SELECT uid, email, display_name, role, status, last_login FROM users_meta');
    console.log('\n📋 Current users:');
    console.table(result.rows);

    console.log('\n✅ Migration complete!');
  } catch (err) {
    console.error('❌ Migration error:', err);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

migrate();
