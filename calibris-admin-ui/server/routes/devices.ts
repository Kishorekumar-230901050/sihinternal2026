// server/routes/devices.ts
// Device management and tamper logging API endpoints
// Connected to Postgres database

import { Router, RequestHandler } from "express";
import { z } from "zod";
import { pool } from "../db";
import { emitTamperAlert, emitBatchTamperAlert } from "../socket";

const router = Router();

// ============================================
// POLL TRACKER - In-memory safe mode detection
// ============================================
// When Luckfox polls /unlock-status, it means device is in safe mode
// Key: device_id (string), Value: last poll timestamp (Date)
const devicePollTracker = new Map<string, Date>();

// Check if device polled within last 35 seconds (is in safe mode)
// Reduced from 60s to 35s for faster status updates after unlock
// (Luckfox polls every 30s, so 35s gives small buffer)
function isDeviceInSafeMode(device_id: string): boolean {
  const lastPoll = devicePollTracker.get(device_id);
  if (!lastPoll) return false;
  const diffSeconds = (Date.now() - lastPoll.getTime()) / 1000;
  return diffSeconds <= 35;
}

// Get seconds since last poll
function getSecondsSinceLastPoll(device_id: string): number | null {
  const lastPoll = devicePollTracker.get(device_id);
  if (!lastPoll) return null;
  return Math.floor((Date.now() - lastPoll.getTime()) / 1000);
}

/** Validation schemas */
const deviceSchema = z.object({
  user_id: z.number().optional(),
  device_type: z.string().optional(),
  purchase_date: z.string().optional(), // ISO8601 date string
});

const tamperLogSchema = z.object({
  device_id: z.string().min(1),
  tamper_type: z.string().optional(),
  severity: z.string().optional(),
  details: z.string().optional(),
  resolution_status: z.string().optional(),
  settling_time: z.number().optional(),
  renewal_cycle: z.number().optional(),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  city: z.string().optional(),
  state: z.string().optional(),
  drift: z.number().optional(),
  prev_hash: z.string().optional(),
  curr_hash: z.string().optional(),
  luckfox_log_id: z.string().optional(),
  event_time: z.string().optional(), // ISO timestamp from device
});

/**
 * GET /api/devices
 * Fetch all devices with their latest tamper information
 */
router.get("/", (async (req, res) => {
  try {
    // Join devices with their latest tamper log
    // Use COALESCE to prefer tamper_log GPS (most recent) but fall back to device registered GPS
    const result = await pool.query(`
      SELECT
        d.device_id,
        d.id,
        d.user_id,
        d.device_type,
        d.purchase_date,
        d.status,
        d.location,
        d.owner,
        d.last_update,
        d.created_at,
        d.last_seen,
        COALESCE(t.latitude, d.latitude) as latitude,
        COALESCE(t.longitude, d.longitude) as longitude,
        COALESCE(t.city, d.city) as city,
        COALESCE(t.state, d.state) as state,
        t.tamper_type,
        t.event_time as tamper_time,
        t.details as tamper_details
      FROM devices d
      LEFT JOIN LATERAL (
        SELECT tamper_type, event_time, details, latitude, longitude, city, state
        FROM tamper_logs
        WHERE device_id = d.device_id::text
        ORDER BY event_time DESC
        LIMIT 1
      ) t ON true
      ORDER BY d.created_at DESC
    `);

    console.log(`✅ Fetched ${result.rows.length} devices with tamper info and GPS coordinates`);
    // Log GPS data for debugging
    result.rows.forEach((row: any) => {
      if (row.latitude || row.longitude) {
        console.log(`📍 Device ${row.device_id}: lat=${row.latitude}, lng=${row.longitude}`);
      }
    });
    res.json(result.rows);
  } catch (err: any) {
    console.error("Error fetching devices:", err);
    res.status(500).json({ error: "Failed to fetch devices" });
  }
}) as RequestHandler);

/**
 * GET /api/devices/recent-activities
 * Get recent tamper events across all devices for dashboard
 */
router.get("/recent-activities", (async (req, res) => {
  try {
    const limit = parseInt(req.query.limit as string) || 20;

    const result = await pool.query(
      `SELECT
        t.id,
        t.device_id,
        t.tamper_type,
        t.severity,
        t.event_time,
        t.details,
        t.latitude,
        t.longitude,
        d.device_type,
        d.location as device_location
       FROM tamper_logs t
       LEFT JOIN devices d ON t.device_id = d.device_id::text
       ORDER BY t.event_time DESC
       LIMIT $1`,
      [limit]
    );

    res.json({
      activities: result.rows
    });
  } catch (err: any) {
    console.error("Error fetching recent activities:", err);
    res.status(500).json({ error: "Failed to fetch recent activities" });
  }
}) as RequestHandler);

/**
 * GET /api/devices/:device_id
 * Fetch a specific device with its tamper logs
 */
router.get("/:device_id", (async (req, res) => {
  try {
    const device_id = parseInt(req.params.device_id);
    if (isNaN(device_id)) {
      return res.status(400).json({ error: "Invalid device_id" });
    }

    const deviceResult = await pool.query("SELECT * FROM devices WHERE device_id = $1", [device_id]);
    if (deviceResult.rows.length === 0) {
      return res.status(404).json({ error: "Device not found" });
    }

    const tamperResult = await pool.query(
      "SELECT * FROM tamper_logs WHERE device_id = $1 ORDER BY event_time DESC",
      [device_id.toString()]
    );

    res.json({
      device: deviceResult.rows[0],
      tamper_logs: tamperResult.rows,
    });
  } catch (err: any) {
    console.error("Error fetching device:", err);
    res.status(500).json({ error: "Failed to fetch device" });
  }
}) as RequestHandler);

/**
 * POST /api/devices
 * Create a new device
 * Example payload:
 * {
 *   "user_id": 1,
 *   "device_type": "motion-sensor",
 *   "purchase_date": "2025-12-10"
 * }
 */
router.post("/", (async (req, res) => {
  try {
    const data = deviceSchema.parse(req.body);

    const insertQuery = `
      INSERT INTO devices (user_id, device_type, purchase_date)
      VALUES ($1, $2, $3)
      RETURNING *
    `;
    const result = await pool.query(insertQuery, [
      data.user_id,
      data.device_type,
      data.purchase_date,
    ]);

    return res.status(201).json({ message: "Device created", device: result.rows[0] });
  } catch (err: any) {
    console.error("Error creating device:", err);
    res.status(400).json({ error: err.message ?? "Failed to create device" });
  }
}) as RequestHandler);

/**
 * POST /api/devices/register
 * Public endpoint for manufacturers to register their devices
 * No authentication required - for manufacturer self-registration
 */
const registerDeviceSchema = z.object({
  device_id: z.number().int().positive("Device ID must be a positive integer"),
  owner_name: z.string().min(1, "Owner name is required"),
  owner_email: z.string().email("Valid email is required"),
  owner_phone: z.string().optional(),
  company_name: z.string().min(1, "Company name is required"),
  device_type: z.string().optional().default("weighing-scale"),
  location: z.string().optional(),
  city: z.string().optional(),
  state: z.string().optional(),
  latitude: z.number().nullable().optional(),
  longitude: z.number().nullable().optional(),
});

router.post("/register", (async (req, res) => {
  try {
    const data = registerDeviceSchema.parse(req.body);

    // Create owner string combining name and company
    const ownerInfo = `${data.owner_name} (${data.company_name}) - ${data.owner_email}${data.owner_phone ? ` - ${data.owner_phone}` : ""}`;

    // Check if device_id already exists
    const existingDevice = await pool.query(
      `SELECT device_id, owner FROM devices WHERE device_id = $1`,
      [data.device_id]
    );

    let device;
    if (existingDevice.rows.length > 0) {
      // Device already exists - check if it's already registered to someone
      if (existingDevice.rows[0].owner && existingDevice.rows[0].owner.trim() !== "") {
        return res.status(400).json({
          error: "Device ID already registered",
          message: `Device ID ${data.device_id} is already registered to another owner. Contact support if this is your device.`
        });
      }

      // Update existing device with manufacturer details
      const result = await pool.query(
        `UPDATE devices SET
          device_type = $1,
          owner = $2,
          location = $3,
          city = $4,
          state = $5,
          latitude = $6,
          longitude = $7,
          status = 'registered',
          last_update = NOW()
        WHERE device_id = $8
        RETURNING *`,
        [
          data.device_type || "weighing-scale",
          ownerInfo,
          data.location || null,
          data.city || null,
          data.state || null,
          data.latitude || null,
          data.longitude || null,
          data.device_id,
        ]
      );
      device = result.rows[0];
      console.log(`📦 DEVICE UPDATED: ID ${device.device_id} by ${data.owner_name} (${data.company_name})`);
    } else {
      // Insert new device with the specific device_id from firmware
      const result = await pool.query(
        `INSERT INTO devices (
          device_id, device_type, owner, location, city, state,
          latitude, longitude, status, created_at, last_update, id
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'registered', NOW(), NOW(), $1)
        RETURNING *`,
        [
          data.device_id,
          data.device_type || "weighing-scale",
          ownerInfo,
          data.location || null,
          data.city || null,
          data.state || null,
          data.latitude || null,
          data.longitude || null,
        ]
      );
      device = result.rows[0];
      console.log(`📦 NEW DEVICE REGISTERED: ID ${device.device_id} by ${data.owner_name} (${data.company_name})`);
    }

    return res.status(201).json({
      message: "Device registered successfully",
      device: {
        device_id: device.device_id,
        owner: data.owner_name,
        company: data.company_name,
        email: data.owner_email,
        device_type: device.device_type,
        location: device.location,
        city: device.city,
        state: device.state,
      },
      instructions: `Your device ID ${device.device_id} has been registered successfully. Your Luckfox device is ready to use.`,
    });
  } catch (err: any) {
    console.error("Error registering device:", err);
    if (err.name === "ZodError") {
      return res.status(400).json({ error: err.errors[0]?.message || "Validation failed" });
    }
    res.status(500).json({ error: "Failed to register device" });
  }
}) as RequestHandler);

/**
 * POST /api/devices/:device_id/tamper
 * Log a tamper event (Luckfox sends tamper detection here)
 * Example payload:
 * {
 *   "tamper_type": "unauthorized-access",
 *   "severity": "high",
 *   "details": "Door opened at 02:30 AM without authorization"
 * }
 */
router.post("/:device_id/tamper", (async (req, res) => {
  try {
    const device_id = parseInt(req.params.device_id);
    if (isNaN(device_id)) {
      return res.status(400).json({ error: "Invalid device_id" });
    }

    const data = tamperLogSchema.parse({ ...req.body, device_id: device_id.toString() });

    // Verify device exists
    const deviceCheck = await pool.query("SELECT * FROM devices WHERE device_id = $1", [device_id]);
    if (deviceCheck.rows.length === 0) {
      return res.status(404).json({ error: "Device not found" });
    }

    // Auto-expire any pending unlock commands for this device (new tamper = device needs fresh unlock)
    const expiredCommands = await pool.query(
      `UPDATE unlock_commands
       SET status = 'expired_by_tamper', executed_at = NOW()
       WHERE device_id = $1 AND status = 'pending'
       RETURNING id`,
      [device_id]
    );
    if (expiredCommands.rows.length > 0) {
      console.log(`🔄 AUTO-EXPIRED: ${expiredCommands.rows.length} pending unlock command(s) for device ${device_id} due to new tamper`);
    }

    // Insert tamper log with all Luckfox fields (device_id stored as TEXT in tamper_logs)
    const eventTime = data.event_time ? new Date(data.event_time) : new Date();
    const result = await pool.query(
      `INSERT INTO tamper_logs (
        device_id, tamper_type, severity, details, event_time,
        resolution_status, settling_time, renewal_cycle,
        latitude, longitude, city, state, drift,
        prev_hash, curr_hash, luckfox_log_id, pushed_at
      )
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, NOW())
       RETURNING *`,
      [
        device_id.toString(), data.tamper_type, data.severity, data.details, eventTime,
        data.resolution_status, data.settling_time, data.renewal_cycle,
        data.latitude, data.longitude, data.city, data.state, data.drift,
        data.prev_hash, data.curr_hash, data.luckfox_log_id
      ]
    );

    // Update device last_seen timestamp (tamper report = device is online)
    await pool.query(
      'UPDATE devices SET last_seen = NOW() WHERE device_id = $1',
      [device_id]
    );

    // Emit real-time alert to all connected WebSocket clients
    const tamperLog = result.rows[0];
    emitTamperAlert(tamperLog);
    console.log(`⚠️ TAMPER ALERT: Device ${device_id} - Broadcasting to dashboard`);

    res.status(201).json({ message: "Tamper logged", tamper_log: tamperLog });
  } catch (err: any) {
    console.error("Error logging tamper:", err);
    res.status(400).json({ error: err.message ?? "Failed to log tamper" });
  }
}) as RequestHandler);

/**
 * POST /api/devices/:device_id/tamper/batch
 * Log multiple tamper events at once (for anna.sh batch sync)
 * Example payload:
 * {
 *   "logs": [
 *     { "tamper_type": "...", "details": "...", ... },
 *     { "tamper_type": "...", "details": "...", ... }
 *   ]
 * }
 */
router.post("/:device_id/tamper/batch", (async (req, res) => {
  try {
    const device_id = parseInt(req.params.device_id);
    if (isNaN(device_id)) {
      return res.status(400).json({ error: "Invalid device_id" });
    }

    const { logs } = req.body;
    if (!Array.isArray(logs) || logs.length === 0) {
      return res.status(400).json({ error: "logs must be a non-empty array" });
    }

    // Verify device exists
    const deviceCheck = await pool.query("SELECT * FROM devices WHERE device_id = $1", [device_id]);
    if (deviceCheck.rows.length === 0) {
      return res.status(404).json({ error: "Device not found" });
    }

    // Auto-expire any pending unlock commands for this device (new tamper batch = device needs fresh unlock)
    const expiredCommands = await pool.query(
      `UPDATE unlock_commands
       SET status = 'expired_by_tamper', executed_at = NOW()
       WHERE device_id = $1 AND status = 'pending'
       RETURNING id`,
      [device_id]
    );
    if (expiredCommands.rows.length > 0) {
      console.log(`🔄 AUTO-EXPIRED: ${expiredCommands.rows.length} pending unlock command(s) for device ${device_id} due to new tamper batch`);
    }

    const insertedLogs = [];
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      for (const log of logs) {
        const data = tamperLogSchema.parse({ ...log, device_id: device_id.toString() });
        const eventTime = data.event_time ? new Date(data.event_time) : new Date();

        const result = await client.query(
          `INSERT INTO tamper_logs (
            device_id, tamper_type, severity, details, event_time,
            resolution_status, settling_time, renewal_cycle,
            latitude, longitude, city, state, drift,
            prev_hash, curr_hash, luckfox_log_id, pushed_at
          )
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, NOW())
           RETURNING *`,
          [
            device_id.toString(), data.tamper_type, data.severity, data.details, eventTime,
            data.resolution_status, data.settling_time, data.renewal_cycle,
            data.latitude, data.longitude, data.city, data.state, data.drift,
            data.prev_hash, data.curr_hash, data.luckfox_log_id
          ]
        );

        insertedLogs.push(result.rows[0]);
      }

      // Update device last_seen timestamp (batch sync = device is online)
      await client.query(
        'UPDATE devices SET last_seen = NOW() WHERE device_id = $1',
        [device_id]
      );

      await client.query('COMMIT');

      // Import batch alert function
      // emitBatchTamperAlert is already imported at the top

      // Emit ONE batch alert instead of individual alerts
      emitBatchTamperAlert(device_id, insertedLogs);
      console.log(`📦 BATCH ALERT: Device ${device_id} - ${insertedLogs.length} tamper logs synced`);

      res.status(201).json({
        message: `${insertedLogs.length} tamper logs created`,
        count: insertedLogs.length,
        logs: insertedLogs
      });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (err: any) {
    console.error("Error batch logging tampers:", err);
    res.status(400).json({ error: err.message ?? "Failed to batch log tampers" });
  }
}) as RequestHandler);

/**
 * GET /api/devices/:device_id/tamper
 * Fetch tamper logs for a specific device
 */
router.get("/:device_id/tamper", (async (req, res) => {
  try {
    const { device_id } = req.params;
    const result = await pool.query(
      "SELECT * FROM tamper_logs WHERE device_id = $1 ORDER BY event_time DESC",
      [device_id]
    );
    res.json(result.rows);
  } catch (err: any) {
    console.error("Error fetching tamper logs:", err);
    res.status(500).json({ error: "Failed to fetch tamper logs" });
  }
}) as RequestHandler);

/**
 * POST /api/devices/:device_id/heartbeat
 * Update device last_seen timestamp (heartbeat)
 * Used by Luckfox devices to report they are online
 */
router.post("/:device_id/heartbeat", (async (req, res) => {
  try {
    const device_id = parseInt(req.params.device_id);
    if (isNaN(device_id)) {
      return res.status(400).json({ error: "Invalid device_id" });
    }

    // Update last_seen timestamp
    await pool.query(
      "UPDATE devices SET last_seen = NOW() WHERE device_id = $1",
      [device_id]
    );

    res.json({
      message: "Heartbeat received",
      device_id,
      timestamp: new Date()
    });
  } catch (err: any) {
    console.error("Heartbeat error:", err);
    res.status(500).json({ error: "Heartbeat failed" });
  }
}) as RequestHandler);

/**
 * GET /api/devices/stats/summary
 * Get device and tamper statistics
 */
router.get("/stats/summary", (async (req, res) => {
  try {
    const devicesResult = await pool.query("SELECT COUNT(*) FROM devices");
    const tampersResult = await pool.query("SELECT COUNT(*) FROM tamper_logs WHERE event_time > NOW() - INTERVAL '24 hours'");

    res.json({
      total_devices: parseInt(devicesResult.rows[0].count),
      tampers_24h: parseInt(tampersResult.rows[0].count),
    });
  } catch (err: any) {
    console.error("Error fetching stats:", err);
    res.status(500).json({ error: "Failed to fetch stats" });
  }
}) as RequestHandler);

/**
 * POST /api/devices/:device_id/unlock
 * Officer requests to unlock a device in safe_mode
 * Creates a pending unlock command that the device will poll for
 * Stores complete officer details for Legal Metrology reports
 */
router.post("/:device_id/unlock", (async (req, res) => {
  try {
    const device_id = parseInt(req.params.device_id);
    if (isNaN(device_id)) {
      return res.status(400).json({ error: "Invalid device_id" });
    }

    const { officer_id, officer_email, reason } = req.body;
    if (!officer_id && !officer_email) {
      return res.status(400).json({ error: "officer_id or officer_email is required" });
    }

    // Verify device exists
    const deviceCheck = await pool.query(
      "SELECT * FROM devices WHERE device_id = $1",
      [device_id]
    );
    if (deviceCheck.rows.length === 0) {
      return res.status(404).json({ error: "Device not found" });
    }

    // Check if device is in safe mode using poll tracker (not database status)
    const isSafeMode = isDeviceInSafeMode(device_id.toString());
    if (!isSafeMode) {
      return res.status(400).json({
        error: "Device is not in safe_mode (not polling)",
        message: "Device must be actively polling to unlock"
      });
    }

    // Check if there's already a pending unlock command (within 1 minute)
    const existingCommand = await pool.query(
      `SELECT * FROM unlock_commands
       WHERE device_id = $1
       AND status = 'pending'
       AND created_at > NOW() - INTERVAL '1 minute'
       ORDER BY created_at DESC
       LIMIT 1`,
      [device_id]
    );

    if (existingCommand.rows.length > 0) {
      // Return the existing pending command instead of creating a duplicate
      console.log(`⏳ UNLOCK ALREADY PENDING: Device ${device_id}`);
      return res.status(200).json({
        message: "Unlock command already pending",
        command: existingCommand.rows[0],
        already_pending: true
      });
    }

    // Lookup officer details from users_meta table
    // Try by UID first (officer_id), then by email
    let officerDetails = { name: "Unknown", email: officer_email || officer_id, role: "officer" };

    try {
      let officerQuery: { rows: Array<{ display_name: string; email: string; role: string }> } | null = null;
      if (officer_id && !officer_id.includes("@")) {
        // officer_id looks like a UID
        officerQuery = await pool.query(
          `SELECT display_name, email, role FROM users_meta WHERE uid = $1`,
          [officer_id]
        );
      }

      // If not found by UID or officer_id contains @, try by email
      if (!officerQuery || officerQuery.rows.length === 0) {
        const emailToSearch = officer_email || officer_id;
        officerQuery = await pool.query(
          `SELECT display_name, email, role FROM users_meta WHERE LOWER(email) = LOWER($1)`,
          [emailToSearch]
        );
      }

      if (officerQuery && officerQuery.rows.length > 0) {
        const officer = officerQuery.rows[0];
        officerDetails = {
          name: officer.display_name || "Unknown",
          email: officer.email,
          role: officer.role || "officer"
        };
      }
    } catch (lookupErr) {
      console.warn("Could not lookup officer details:", lookupErr);
      // Continue with default values
    }

    // Create unlock command with full officer details
    const result = await pool.query(
      `INSERT INTO unlock_commands (device_id, officer_id, officer_name, officer_email, officer_role, reason, status, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, 'pending', NOW())
       RETURNING *`,
      [device_id, officer_id, officerDetails.name, officerDetails.email, officerDetails.role, reason || "Remote unlock via dashboard"]
    );

    const command_id = result.rows[0].id;
    console.log(`🔓 UNLOCK REQUEST: Device ${device_id} by ${officerDetails.name} (${officerDetails.email}), Role: ${officerDetails.role}, Command ID: ${command_id}`);

    // IMPORTANT: Do NOT change device status here!
    // The unlock flow is:
    // 1. Dashboard creates unlock command (this endpoint)
    // 2. Luckfox device polls and detects the command
    // 3. Luckfox device exits safe mode locally
    // 4. Luckfox device calls /unlock-confirm endpoint
    // 5. ONLY THEN does the backend update device status to "online"

    res.status(201).json({
      message: "Unlock command created - device will unlock within 60 seconds",
      command: result.rows[0]
    });
  } catch (err: any) {
    console.error("Error creating unlock command:", err);
    res.status(500).json({ error: "Failed to create unlock command" });
  }
}) as RequestHandler);

/**
 * GET /api/devices/:device_id/unlock-status
 * Luckfox polls this endpoint every 30 seconds when in safe mode
 * Tracks polling to detect safe mode status
 */
router.get("/:device_id/unlock-status", (async (req, res) => {
  const device_id = req.params.device_id;

  // Track this poll - device is in safe mode if it's polling
  devicePollTracker.set(device_id, new Date());
  console.log(`📡 POLL RECEIVED: Device ${device_id} at ${new Date().toISOString()} - Marked as SAFE MODE`);

  try {
    // Check for pending unlock commands (not expired)
    const result = await pool.query(
      `SELECT * FROM unlock_commands
       WHERE device_id = $1
       AND status = 'pending'
       AND created_at > NOW() - INTERVAL '1 minute'
       ORDER BY created_at DESC
       LIMIT 1`,
      [parseInt(device_id)]
    );

    // Auto-expire old pending commands
    await pool.query(
      `UPDATE unlock_commands
       SET status = 'expired'
       WHERE device_id = $1
       AND status = 'pending'
       AND created_at <= NOW() - INTERVAL '1 minute'`,
      [parseInt(device_id)]
    );

    if (result.rows.length > 0) {
      console.log(`🔓 UNLOCK PENDING for Device ${device_id} - Command ID: ${result.rows[0].id}`);
      res.json({
        unlock_pending: true,
        command_id: result.rows[0].id,
        officer_id: result.rows[0].officer_id,
        reason: result.rows[0].reason
      });
    } else {
      res.json({
        unlock_pending: false
      });
    }
  } catch (err: any) {
    console.error("Error checking unlock status:", err);
    res.status(500).json({ error: "Failed to check unlock status" });
  }
}) as RequestHandler);

/**
 * POST /api/devices/:device_id/unlock-confirm
 * Device confirms it has executed the unlock command
 * Updates command status to 'executed' and device status to 'online'
 */
router.post("/:device_id/unlock-confirm", (async (req, res) => {
  try {
    const device_id = parseInt(req.params.device_id);
    if (isNaN(device_id)) {
      return res.status(400).json({ error: "Invalid device_id" });
    }

    const { command_id } = req.body;
    if (!command_id) {
      return res.status(400).json({ error: "command_id is required" });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Update command status to executed
      await client.query(
        `UPDATE unlock_commands
         SET status = 'executed', executed_at = NOW()
         WHERE id = $1 AND device_id = $2`,
        [command_id, device_id]
      );

      // Update device status to online
      await client.query(
        `UPDATE devices
         SET status = 'online', last_seen = NOW()
         WHERE device_id = $1`,
        [device_id]
      );

      await client.query('COMMIT');

      // Clear poll tracker - device is no longer in safe mode
      devicePollTracker.delete(device_id.toString());
      console.log(`✅ UNLOCK CONFIRMED: Device ${device_id} returned to normal operation (poll tracker cleared)`)

      res.json({
        message: "Unlock confirmed",
        device_id,
        new_status: "online"
      });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (err: any) {
    console.error("Error confirming unlock:", err);
    res.status(500).json({ error: "Failed to confirm unlock" });
  }
}) as RequestHandler);

/**
 * GET /api/devices/:device_id/unlock-history
 * Get all unlock commands for a specific device
 */
router.get("/:device_id/unlock-history", (async (req, res) => {
  try {
    const device_id = parseInt(req.params.device_id);
    if (isNaN(device_id)) {
      return res.status(400).json({ error: "Invalid device_id" });
    }

    const result = await pool.query(
      `SELECT * FROM unlock_commands
       WHERE device_id = $1
       ORDER BY created_at DESC`,
      [device_id]
    );

    res.json({
      device_id,
      unlock_commands: result.rows
    });
  } catch (err: any) {
    console.error("Error fetching unlock history:", err);
    res.status(500).json({ error: "Failed to fetch unlock history" });
  }
}) as RequestHandler);

/**
 * GET /api/devices/:device_id/tamper-stats
 * Get tamper event statistics for a specific device
 */
router.get("/:device_id/tamper-stats", (async (req, res) => {
  try {
    const device_id = parseInt(req.params.device_id);
    if (isNaN(device_id)) {
      return res.status(400).json({ error: "Invalid device_id" });
    }

    // Get counts by tamper type
    const result = await pool.query(
      `SELECT
        tamper_type,
        COUNT(*) as count
       FROM tamper_logs
       WHERE device_id = $1
       GROUP BY tamper_type
       ORDER BY count DESC`,
      [device_id.toString()]
    );

    // Get total tamper count
    const totalResult = await pool.query(
      `SELECT COUNT(*) as total FROM tamper_logs WHERE device_id = $1`,
      [device_id.toString()]
    );

    res.json({
      device_id,
      total_tampers: parseInt(totalResult.rows[0]?.total || '0'),
      by_type: result.rows
    });
  } catch (err: any) {
    console.error("Error fetching tamper stats:", err);
    res.status(500).json({ error: "Failed to fetch tamper statistics" });
  }
}) as RequestHandler);

/**
 * GET /api/devices/:device_id/status
 * Frontend polls this to check if device is in safe mode (based on poll tracker)
 * Returns polling-based status without needing database status field
 */
router.get("/:device_id/status", (async (req, res) => {
  try {
    const device_id = req.params.device_id;
    const isSafeMode = isDeviceInSafeMode(device_id);
    const lastPollSecondsAgo = getSecondsSinceLastPoll(device_id);

    console.log(`📊 STATUS CHECK: Device ${device_id} - Safe Mode: ${isSafeMode}, Last Poll: ${lastPollSecondsAgo}s ago`);

    res.json({
      device_id,
      status: isSafeMode ? "safe_mode" : "online",
      is_tampered: isSafeMode,
      can_unlock: isSafeMode,
      last_poll_seconds_ago: lastPollSecondsAgo
    });
  } catch (err: any) {
    console.error("Error checking device status:", err);
    res.status(500).json({ error: "Failed to check device status" });
  }
}) as RequestHandler);

/**
 * GET /api/devices/:device_id/audit-logs
 * Get comprehensive audit logs for Legal Metrology Department
 * Includes tamper events, unlock commands, and device details
 */
router.get("/:device_id/audit-logs", (async (req, res) => {
  try {
    const device_id = parseInt(req.params.device_id);
    if (isNaN(device_id)) {
      return res.status(400).json({ error: "Invalid device_id" });
    }

    // Get device details
    const deviceResult = await pool.query(
      `SELECT * FROM devices WHERE device_id = $1`,
      [device_id]
    );
    if (deviceResult.rows.length === 0) {
      return res.status(404).json({ error: "Device not found" });
    }
    const device = deviceResult.rows[0];

    // Get all tamper events
    const tamperResult = await pool.query(
      `SELECT
        id,
        tamper_type,
        severity,
        event_time,
        resolution_status,
        details,
        latitude,
        longitude,
        city,
        state,
        drift,
        settling_time,
        prev_hash,
        curr_hash,
        luckfox_log_id,
        pushed_at
       FROM tamper_logs
       WHERE device_id = $1
       ORDER BY event_time DESC`,
      [device_id.toString()]
    );

    // Get all unlock commands with officer details
    const unlockResult = await pool.query(
      `SELECT
        id,
        officer_id,
        officer_name,
        officer_email,
        officer_role,
        reason,
        status,
        created_at,
        executed_at
       FROM unlock_commands
       WHERE device_id = $1
       ORDER BY created_at DESC`,
      [device_id]
    );

    // Calculate statistics
    const stats = {
      total_tamper_events: tamperResult.rows.length,
      total_unlocks: unlockResult.rows.filter(u => u.status === 'executed').length,
      pending_unlocks: unlockResult.rows.filter(u => u.status === 'pending').length,
      tamper_types: {} as Record<string, number>,
      severity_breakdown: {} as Record<string, number>,
      first_tamper: tamperResult.rows.length > 0 ? tamperResult.rows[tamperResult.rows.length - 1].event_time : null,
      last_tamper: tamperResult.rows.length > 0 ? tamperResult.rows[0].event_time : null,
    };

    // Count by tamper type and severity
    tamperResult.rows.forEach(t => {
      stats.tamper_types[t.tamper_type] = (stats.tamper_types[t.tamper_type] || 0) + 1;
      stats.severity_breakdown[t.severity] = (stats.severity_breakdown[t.severity] || 0) + 1;
    });

    res.json({
      device,
      tamper_events: tamperResult.rows,
      unlock_commands: unlockResult.rows,
      statistics: stats
    });
  } catch (err: any) {
    console.error("Error fetching audit logs:", err);
    res.status(500).json({ error: "Failed to fetch audit logs" });
  }
}) as RequestHandler);

// GET /api/devices/:device_id/recent-events - Get recent tamper events for a device
router.get("/:device_id/recent-events", (async (req, res) => {
  try {
    const device_id = parseInt(req.params.device_id);
    if (isNaN(device_id)) {
      return res.status(400).json({ error: "Invalid device_id" });
    }

    const limit = parseInt(req.query.limit as string) || 10;

    const result = await pool.query(
      `SELECT
        id,
        tamper_type,
        severity,
        event_time,
        resolution_status,
        details
       FROM tamper_logs
       WHERE device_id = $1
       ORDER BY event_time DESC
       LIMIT $2`,
      [device_id.toString(), limit]
    );

    res.json({
      device_id,
      events: result.rows
    });
  } catch (err: any) {
    console.error("Error fetching recent events:", err);
    res.status(500).json({ error: "Failed to fetch recent events" });
  }
}) as RequestHandler);

export default router;
