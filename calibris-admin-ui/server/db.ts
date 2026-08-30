import { Pool } from "pg";
import dotenv from "dotenv";

dotenv.config();

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error("DATABASE_URL is not set. Please add it to your .env file.");
}

export const pool = new Pool({
  connectionString,
  ssl: {
    rejectUnauthorized: false  // Works with Railway from anywhere
  },
  max: 5,
  min: 1,
  idleTimeoutMillis: 10000,
  connectionTimeoutMillis: 5000,
  keepAlive: true,
  keepAliveInitialDelayMillis: 10000,
});

pool.on("error", (err) => {
  console.error("Database pool error:", err.message);
});

pool.on("remove", () => {
  console.log("Database connection removed from pool");
});

export async function pingDb(): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query("SELECT 1");
  } finally {
    client.release();
  }
}
