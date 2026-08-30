# Remote Device Unlock - Testing Guide

## Overview
This guide explains how to test the remote device unlock feature locally before deploying to production.

## What Was Implemented

### 1. Database Schema
**File**: `server/migrations/004_add_unlock_commands.sql`
- New table: `unlock_commands`
- Tracks unlock requests from officers
- Status field: `pending`, `executed`, `expired`, `failed`

### 2. Backend API Endpoints
**File**: `server/routes/devices.ts`

Three new endpoints added:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/devices/:device_id/unlock` | POST | Officer requests unlock |
| `/api/devices/:device_id/unlock-status` | GET | Device checks for unlock commands |
| `/api/devices/:device_id/unlock-confirm` | POST | Device confirms unlock success |

### 3. Luckfox Script
**File**: `check_unlock_command.sh`
- Polls backend API every 60 seconds
- Checks for pending unlock commands
- Executes unlock (updates config.json, restarts services)
- Confirms unlock to backend

### 4. Frontend Dashboard
**File**: `client/components/DeviceDetailsPanel.tsx`
- "Unlock Device" button (only shows if device is Tampered or in safe_mode)
- Confirmation dialog before unlocking
- Success/error messages
- Loading state during unlock

## Testing Locally

### Step 1: Apply Database Migration

Run this SQL on your local PostgreSQL database:

```bash
# Connect to your local database
psql -U your_username -d your_database_name

# Run the migration
\i server/migrations/004_add_unlock_commands.sql
```

Or manually create the table:

```sql
CREATE TABLE unlock_commands (
  id SERIAL PRIMARY KEY,
  device_id INTEGER NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  officer_id VARCHAR(255) NOT NULL,
  reason TEXT,
  status VARCHAR(50) NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  executed_at TIMESTAMP,
  CONSTRAINT valid_status CHECK (status IN ('pending', 'executed', 'expired', 'failed'))
);

CREATE INDEX idx_unlock_commands_device_status ON unlock_commands(device_id, status);
CREATE INDEX idx_unlock_commands_pending ON unlock_commands(status, created_at) WHERE status = 'pending';
```

### Step 2: Start Local Backend

```bash
cd "c:\Users\deepa\Desktop\calabris software\Calibris-software"
npm run dev
```

Backend should start on: `http://localhost:3000`

### Step 3: Test API Endpoints (Using Postman or curl)

#### 3a. Create Unlock Command

```bash
curl -X POST http://localhost:3000/api/devices/1/unlock \
  -H "Content-Type: application/json" \
  -d '{
    "officer_id": "admin@calibris.com",
    "reason": "Testing remote unlock"
  }'
```

**Expected Response**:
```json
{
  "message": "Unlock command created. Device will unlock within 60 seconds.",
  "command": {
    "id": 1,
    "device_id": 1,
    "officer_id": "admin@calibris.com",
    "reason": "Testing remote unlock",
    "status": "pending",
    "created_at": "2025-12-11T10:30:00.000Z"
  }
}
```

#### 3b. Check Unlock Status (Simulating Luckfox Device)

```bash
curl http://localhost:3000/api/devices/1/unlock-status
```

**Expected Response (if command pending)**:
```json
{
  "unlock_pending": true,
  "command_id": 1,
  "officer_id": "admin@calibris.com",
  "reason": "Testing remote unlock",
  "created_at": "2025-12-11T10:30:00.000Z"
}
```

**Expected Response (if no command)**:
```json
{
  "unlock_pending": false
}
```

#### 3c. Confirm Unlock (Simulating Luckfox Device)

```bash
curl -X POST http://localhost:3000/api/devices/1/unlock-confirm \
  -H "Content-Type: application/json" \
  -d '{"command_id": 1}'
```

**Expected Response**:
```json
{
  "message": "Unlock confirmed",
  "command": {
    "id": 1,
    "status": "executed",
    "executed_at": "2025-12-11T10:31:00.000Z"
  }
}
```

### Step 4: Test Frontend Dashboard

1. Open: `http://localhost:5173` (or your frontend dev port)
2. Log in to dashboard
3. Select a device
4. Manually change device status to "Tampered" or "safe_mode" in database:

```sql
UPDATE devices SET status = 'safe_mode' WHERE device_id = '1';
```

5. Refresh dashboard - you should see "Unlock Device" button
6. Click "Unlock Device"
7. Confirm in dialog
8. Check backend console for log: `🔓 Unlock command created for Device 1 by admin@calibris.com`

### Step 5: Test Luckfox Script (Simulated)

Since you're testing locally without the actual Luckfox device, you can test the script logic:

#### Option A: Test on Windows (using Git Bash or WSL)

```bash
# Update script to use localhost
sed -i 's|calibris-fullstack-production.up.railway.app|localhost:3000|g' check_unlock_command.sh

# Make executable
chmod +x check_unlock_command.sh

# Run once
./check_unlock_command.sh

# Check log
cat /tmp/unlock.log  # Or wherever you set LOG_FILE
```

#### Option B: Test the unlock check manually

```bash
# Create unlock command via dashboard or API
# Then check status
curl http://localhost:3000/api/devices/1/unlock-status

# Simulate device confirmation
curl -X POST http://localhost:3000/api/devices/1/unlock-confirm \
  -H "Content-Type: application/json" \
  -d '{"command_id": 1}'
```

## Complete Test Flow

### End-to-End Test

1. **Setup**: Device is in safe_mode
   ```sql
   UPDATE devices SET status = 'safe_mode' WHERE device_id = '1';
   ```

2. **Officer Action**: Officer clicks "Unlock Device" on dashboard
   - Frontend calls: `POST /api/devices/1/unlock`
   - Backend creates unlock_command with status='pending'

3. **Device Polling**: Luckfox script checks for unlock (every 60s)
   - Script calls: `GET /api/devices/1/unlock-status`
   - Backend returns: `{unlock_pending: true, command_id: 1}`

4. **Device Unlock**: Script performs unlock
   - Updates config.json
   - Stops safe_mode.service
   - Starts measure_weight.service
   - Calls: `POST /api/devices/1/unlock-confirm`
   - Backend updates command status to 'executed'
   - Backend updates device status to 'online'

5. **Verification**: Check database
   ```sql
   SELECT * FROM unlock_commands WHERE device_id = (SELECT id FROM devices WHERE device_id = '1');
   SELECT status FROM devices WHERE device_id = '1';
   ```

## Testing Checklist

- [ ] Database migration applied successfully
- [ ] Backend starts without errors
- [ ] Can create unlock command via API
- [ ] Can check unlock status via API
- [ ] Can confirm unlock via API
- [ ] Frontend shows "Unlock Device" button when device is Tampered/safe_mode
- [ ] Button doesn't show for Online devices
- [ ] Confirmation dialog appears when clicking unlock
- [ ] Success message shows after unlock command sent
- [ ] Backend console logs unlock command creation
- [ ] Luckfox script can detect pending unlock (if testing with actual device)
- [ ] Database records are created correctly

## Troubleshooting

### Backend Error: "unlock_commands table does not exist"
**Fix**: Run the database migration (Step 1)

### Frontend Error: "Cannot read property 'id'"
**Fix**: Make sure a device is selected in the dashboard

### Unlock button not showing
**Fix**: Device status must be "Tampered" or "safe_mode". Update in database:
```sql
UPDATE devices SET status = 'safe_mode' WHERE device_id = '1';
```

### API returns 404 for unlock endpoints
**Fix**: Make sure you restarted the backend after adding the new routes

### Luckfox script can't connect to API
**Fix**: Check API_BASE variable in script. For local testing, use `http://localhost:3000/api`

## Deployment to Production

Once local testing is complete:

1. **Push to GitHub**:
```bash
git add .
git commit -m "Add remote device unlock feature"
git push origin master
```

2. **Railway (Backend) - Auto-deploys**:
   - Migration will need to be run manually on production database
   - Or add migration runner to deployment process

3. **Vercel (Frontend) - Auto-deploys**:
   - No changes needed, environment variables already configured

4. **Luckfox Devices**:
   - Upload `check_unlock_command.sh` to each device
   - Add to crontab: `* * * * * /home/pico/calibris/check_unlock_command.sh`
   - Make executable: `chmod +x check_unlock_command.sh`
   - Verify API_BASE uses production URL

## Security Considerations

- Unlock commands expire after 5 minutes (prevents replay attacks)
- Officer ID is logged for audit trail
- Device must confirm unlock (two-way verification)
- Only authorized users can access dashboard (Firebase auth)

## Feature Summary

**What it does**:
- Officer clicks "Unlock" button on dashboard
- Backend creates unlock command
- Device polls API and detects unlock command
- Device automatically exits safe mode
- Device confirms unlock to backend
- Officer sees success message

**Benefits**:
- No physical access needed to unlock device
- Unlock within 60 seconds (polling interval)
- Full audit trail in database
- Two unlock methods (local TOTP + remote API)
