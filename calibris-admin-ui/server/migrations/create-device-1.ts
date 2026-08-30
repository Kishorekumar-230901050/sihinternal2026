// server/migrations/create-device-1.ts
// Create device with ID = 1 for Luckfox

import "dotenv/config";
import { pool } from "../db";

async function createDevice1() {
  console.log("🔧 Creating device with ID = 1 for Luckfox...\n");

  try {
    // Insert device with specific ID = 1
    const result = await pool.query(
      `INSERT INTO devices (device_id, device_type, purchase_date)
       VALUES (1, 'luckfox-tamper-detector', '2025-12-10')
       RETURNING *`
    );

    const device = result.rows[0];

    console.log("✅ Device created successfully!");
    console.log("\n📋 Device Details:");
    console.log(`   Device ID: ${device.device_id}`);
    console.log(`   Device Type: ${device.device_type}`);
    console.log(`   Purchase Date: ${device.purchase_date}`);

    console.log("\n✅ Your Luckfox can now send tamper logs to:");
    console.log(`   POST /api/devices/1/tamper`);

  } catch (error: any) {
    if (error.code === '23505') {
      console.log("ℹ️  Device with ID = 1 already exists");
    } else {
      console.error("❌ Failed to create device:", error);
      process.exit(1);
    }
  } finally {
    await pool.end();
  }
}

createDevice1();
