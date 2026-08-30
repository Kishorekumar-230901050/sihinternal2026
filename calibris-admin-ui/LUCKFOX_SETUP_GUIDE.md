# Luckfox Device Setup Guide - Online/Offline Status Tracking

## Overview

This guide helps you set up your 2 Luckfox devices to report their online/offline status in real-time for the jury presentation.

---

## Step 1: Upload Heartbeat Scripts to Luckfox Devices

### **For Device 1:**

1. Copy `luckfox-heartbeat-device1.sh` to your Luckfox Device 1:
   ```bash
   scp luckfox-heartbeat-device1.sh pico@<device1-ip>:/home/pico/calibris/heartbeat.sh
   ```

2. SSH into Device 1 and make it executable:
   ```bash
   ssh pico@<device1-ip>
   chmod +x /home/pico/calibris/heartbeat.sh
   ```

3. Update the ngrok URL in the script:
   ```bash
   nano /home/pico/calibris/heartbeat.sh
   # Change: API_BASE="https://your-ngrok-url.ngrok-free.dev/api"
   # To: API_BASE="https://your-actual-ngrok-url.ngrok-free.dev/api"
   ```

### **For Device 2:**

1. Copy `luckfox-heartbeat-device2.sh` to your Luckfox Device 2:
   ```bash
   scp luckfox-heartbeat-device2.sh pico@<device2-ip>:/home/pico/calibris/heartbeat.sh
   ```

2. SSH into Device 2 and make it executable:
   ```bash
   ssh pico@<device2-ip>
   chmod +x /home/pico/calibris/heartbeat.sh
   ```

3. Update the ngrok URL in the script (same as Device 1)

---

## Step 2: Set Up Cron Jobs

### **On Both Devices:**

1. Edit crontab:
   ```bash
   crontab -e
   ```

2. Add these lines (runs every 30 seconds):
   ```cron
   # Heartbeat every 30 seconds
   * * * * * /home/pico/calibris/heartbeat.sh
   * * * * * sleep 30; /home/pico/calibris/heartbeat.sh
   ```

3. Save and exit (Ctrl+X, then Y, then Enter)

4. Verify cron is running:
   ```bash
   crontab -l
   ```

---

## Step 3: Start Your Backend Server

1. Make sure your backend is running:
   ```bash
   npm run dev
   ```

2. Start ngrok (in a separate terminal):
   ```bash
   ngrok http 3000
   ```

3. Copy the ngrok URL (e.g., `https://abc123.ngrok-free.dev`)

4. Update both heartbeat scripts on the Luckfox devices with this URL

---

## Step 4: Test the Heartbeat

### **Test Device 1:**

SSH into Device 1 and manually run the heartbeat:
```bash
ssh pico@<device1-ip>
/home/pico/calibris/heartbeat.sh
```

You should see in your backend logs:
```
Heartbeat received from Device 1
```

### **Test Device 2:**

```bash
ssh pico@<device2-ip>
/home/pico/calibris/heartbeat.sh
```

---

## Step 5: Verify Dashboard Display

1. Open your dashboard: `http://localhost:5173`

2. You should see:
   - **Total Devices**: 20 (or your total count)
   - **Online**: 2 (or more, depending on when devices last reported)
   - **Offline**: 18 (or fewer)

3. The counts update automatically every 10 seconds

---

## How It Works

### **Heartbeat Mechanism:**

- Devices send a POST request to `/api/devices/:device_id/heartbeat` every 30 seconds
- Backend updates the `last_seen` timestamp in the database
- Dashboard calculates status:
  - **Online** 🟢: `last_seen` < 2 minutes ago
  - **Offline** 🔴: `last_seen` > 2 minutes ago

### **Database Schema:**

```sql
devices (
  device_id INTEGER PRIMARY KEY,
  last_seen TIMESTAMP DEFAULT NOW(),
  ...
)
```

---

## Jury Presentation Demo

### **Demo 1: Show Both Devices Online**

1. Make sure both Luckfox devices are running with cron jobs active
2. Open dashboard
3. Point to the stats: "You can see Device 1 and Device 2 are currently **online** (green indicators)"

### **Demo 2: Show Device Going Offline**

1. SSH into Device 1
2. Stop the cron job:
   ```bash
   crontab -e
   # Comment out the heartbeat lines with #
   ```
3. Wait 2 minutes
4. Refresh dashboard
5. Point out: "Device 1 is now **offline** because it stopped reporting"
6. Re-enable cron job to show it coming back online

### **Demo 3: Real-time Status Tracking**

Say to jury:
> "Our system tracks device health in real-time using heartbeat monitoring. Every 30 seconds, each device reports to our backend. If a device stops reporting for more than 2 minutes, we automatically mark it as offline and alert the monitoring team. This is critical for cold chain monitoring where device failure can lead to spoilage."

---

## Troubleshooting

### **Heartbeat not working?**

1. Check ngrok URL is correct in the script:
   ```bash
   cat /home/pico/calibris/heartbeat.sh | grep API_BASE
   ```

2. Test heartbeat manually:
   ```bash
   /home/pico/calibris/heartbeat.sh
   ```

3. Check backend logs for errors

4. Verify device has internet access:
   ```bash
   ping google.com
   ```

### **Cron not running?**

1. Check cron status:
   ```bash
   sudo systemctl status cron
   ```

2. View cron logs:
   ```bash
   grep CRON /var/log/syslog
   ```

### **Dashboard not updating?**

1. Hard refresh browser (Ctrl+Shift+R)
2. Check if backend is running
3. Verify database migration ran successfully:
   ```bash
   npm run migrate:004
   ```

---

## Quick Reference

### **Important Files:**

- `server/routes/devices.ts` - Heartbeat endpoint (line 279)
- `client/pages/Dashboard.tsx` - Status calculation (line 17)
- `server/migrations/004-add-last-seen.sql` - Database schema
- `luckfox-heartbeat-device1.sh` - Device 1 heartbeat script
- `luckfox-heartbeat-device2.sh` - Device 2 heartbeat script

### **Important URLs:**

- Heartbeat endpoint: `POST /api/devices/:device_id/heartbeat`
- Dashboard: `http://localhost:5173`
- Backend: `http://localhost:3000`

---

## Alternative: Use Existing anna.sh (Simpler!)

If you don't want to set up dedicated heartbeat scripts, you can use your existing `anna.sh` which already syncs data every minute. The batch sync automatically updates `last_seen` when it runs.

**Pros:**
- No additional setup needed
- Already working
- Keeps devices "online" as long as anna.sh runs

**Cons:**
- Less precise (1-minute intervals vs 30-second heartbeats)
- Tied to data sync (if sync fails, device appears offline)

**To use anna.sh instead:**

Just make sure your anna.sh runs every minute via cron:
```bash
crontab -e

# Add this line
* * * * * /home/pico/calibris/anna.sh >> /home/pico/calibris/data/sync.log 2>&1
```

That's it! The batch endpoint (`/api/devices/:device_id/tamper/batch`) will automatically update `last_seen` when anna.sh syncs.

---

## Summary

✅ Heartbeat scripts created for both devices
✅ Backend endpoint ready (`POST /devices/:device_id/heartbeat`)
✅ Dashboard calculates online/offline status
✅ Database migration complete
✅ Cron job setup documented
✅ Jury demo script ready

**You're all set for the jury presentation!** 🎉
