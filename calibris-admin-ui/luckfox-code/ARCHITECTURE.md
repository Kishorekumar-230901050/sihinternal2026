# Real-time Tamper Alert Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         LUCKFOX DEVICE                               │
│                                                                       │
│  ┌──────────────────┐                                                │
│  │  Tamper Sensor   │                                                │
│  │  - Accelerometer │                                                │
│  │  - Temperature   │                                                │
│  │  - Physical      │                                                │
│  └────────┬─────────┘                                                │
│           │                                                           │
│           ▼                                                           │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │  log_tamper_realtime()                                   │       │
│  │  (tamper_logs_realtime.c)                                │       │
│  └──────────────────┬───────────────────────────────────────┘       │
│                     │                                                │
│         ┌───────────┴────────────┐                                   │
│         │                        │                                   │
│         ▼                        ▼                                   │
│  ┌─────────────┐        ┌──────────────────┐                        │
│  │   SQLite    │        │  Check Network   │                        │
│  │  (mydata.db)│        │   Available?     │                        │
│  └─────────────┘        └────────┬─────────┘                        │
│   ✅ Always saves             │                                     │
│                          ┌─────┴─────┐                               │
│                          │           │                               │
│                       YES│           │NO                             │
│                          │           │                               │
│                          ▼           ▼                               │
│                  ┌─────────────┐  ┌──────────────┐                  │
│                  │ HTTP POST   │  │  Skip alert  │                  │
│                  │ (cURL)      │  │ (anna.sh     │                  │
│                  │ Non-blocking│  │  will sync)  │                  │
│                  └──────┬──────┘  └──────────────┘                  │
│                         │                                            │
└─────────────────────────┼────────────────────────────────────────────┘
                          │
                          │ HTTPS (via ngrok)
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      BACKEND SERVER                                  │
│                      (Express.js + Socket.IO)                        │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │  POST /api/devices/1/tamper                              │       │
│  │  (routes/devices.ts)                                     │       │
│  └────────────────────┬─────────────────────────────────────┘       │
│                       │                                              │
│           ┌───────────┴────────────┐                                 │
│           │                        │                                 │
│           ▼                        ▼                                 │
│  ┌─────────────────┐    ┌──────────────────────┐                    │
│  │   PostgreSQL    │    │  emitTamperAlert()   │                    │
│  │ (tamper_logs)   │    │   (socket.ts)        │                    │
│  └─────────────────┘    └──────────┬───────────┘                    │
│   ✅ Saved to DB                 │                                  │
│                                   │                                  │
│                                   │ WebSocket emit                   │
│                                   │ "tamper:alert"                   │
└───────────────────────────────────┼──────────────────────────────────┘
                                    │
                                    │ WebSocket (Socket.IO)
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      FRONTEND DASHBOARD                              │
│                      (React + Socket.IO Client)                      │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │  useTamperAlerts() Hook                                  │       │
│  │  (hooks/useTamperAlerts.ts)                              │       │
│  └────────────────────┬─────────────────────────────────────┘       │
│                       │                                              │
│                       │ Receives "tamper:alert"                      │
│                       │                                              │
│                       ▼                                              │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │  TamperAlertListener Component                           │       │
│  │  - Shows connection status                               │       │
│  │  - Displays latest alert                                 │       │
│  │  - Shows alert history                                   │       │
│  │  - Toast notifications                                   │       │
│  └──────────────────────────────────────────────────────────┘       │
│                                                                       │
│  🚨 User sees alert INSTANTLY!                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## Data Flow Timeline

### Real-time Path (Network Available)

```
T+0.0s  → Tamper detected on Luckfox
T+0.1s  → log_tamper_realtime() called
T+0.2s  → Saved to SQLite ✅
T+0.3s  → Network check: AVAILABLE
T+0.3s  → Background thread spawned
T+0.5s  → HTTP POST sent to backend
T+1.0s  → Backend receives, saves to PostgreSQL
T+1.1s  → Backend emits WebSocket event
T+1.2s  → Dashboard receives event
T+1.2s  → 🚨 USER SEES ALERT! 🚨
T+1.3s  → Toast notification appears
```

**Total latency: ~1.2 seconds** ⚡

### Backup Path (Network Down)

```
T+0.0s  → Tamper detected on Luckfox
T+0.1s  → log_tamper_realtime() called
T+0.2s  → Saved to SQLite ✅
T+0.3s  → Network check: UNAVAILABLE
T+0.3s  → Skip real-time alert
...
T+300s  → anna.sh runs (5-minute cron)
T+301s  → Reads from SQLite
T+302s  → POSTs to backend
T+303s  → Backend saves & emits WebSocket
T+304s  → 🚨 USER SEES ALERT (delayed)
```

**Total latency: ~5 minutes** (but guaranteed delivery)

## Components

### 1. Luckfox C Library

**File:** `tamper_logs_realtime.c`

**Key Functions:**
- `init_tamper_logging()` - Initialize database and cURL
- `log_tamper_realtime()` - Log event + send alert
- `send_tamper_alert()` - HTTP POST to backend
- `check_network_available()` - Quick network check

**Dependencies:**
- libcurl (HTTP requests)
- libssl (SHA-256 hashing)
- libsqlite3 (local storage)
- pthread (background threads)

### 2. Backend API

**Files:**
- `server/socket.ts` - WebSocket server
- `server/routes/devices.ts` - REST API
- `server/dev-server.ts` - HTTP + WebSocket server

**Key Functions:**
- `POST /api/devices/:device_id/tamper` - Receive tamper event
- `emitTamperAlert()` - Broadcast to all connected clients
- `initializeSocket()` - Start WebSocket server

### 3. Frontend Dashboard

**Files:**
- `client/hooks/useTamperAlerts.ts` - WebSocket hook
- `client/components/TamperAlertListener.tsx` - Alert UI
- `client/pages/Dashboard.tsx` - Main dashboard

**Features:**
- Real-time connection status indicator
- Latest alert display
- Alert history (last 50)
- Toast notifications

### 4. Backup Sync Script

**File:** `luckfox-anna.sh`

**Purpose:** Guarantees data delivery if:
- Network was down during tamper
- HTTP request timed out
- Backend server was offline
- Real-time alert failed for any reason

**Schedule:** Runs every 5 minutes via cron

## Reliability Features

### Multi-layer Redundancy

1. **SQLite** - Local persistence (never loses data)
2. **Real-time alerts** - Fast when network available
3. **anna.sh** - Backup sync for missed events
4. **PostgreSQL** - Permanent cloud storage

### Network Resilience

- Quick network check (1 second timeout)
- Non-blocking background threads
- Graceful degradation (skip alert if network down)
- Automatic retry via anna.sh

### Thread Safety

- Mutex locks for SQLite writes
- Separate threads for HTTP requests
- No blocking of main tamper detection

## Performance Characteristics

| Metric | Value |
|--------|-------|
| SQLite write time | ~50ms |
| Network check | ~100ms |
| HTTP POST (success) | ~500ms |
| HTTP POST (timeout) | ~3s |
| WebSocket latency | ~10ms |
| Total real-time latency | **~1.2s** |
| Backup sync interval | 5 minutes |

## Deployment Checklist

- [ ] Backend server running on port 3000
- [ ] Ngrok tunnel active
- [ ] API_ENDPOINT updated in tamper_logs_realtime.h
- [ ] Library compiled on Luckfox
- [ ] Test program runs successfully
- [ ] Dashboard shows "🟢 Connected"
- [ ] Test alert received on dashboard
- [ ] anna.sh cron job still active

## Testing Guide

### 1. Test Network Available

```bash
# On Luckfox
./test_tamper
```

**Expected:**
- Console: "✅ Tamper logged to SQLite"
- Console: "🚨 Real-time alert sent successfully"
- Dashboard: Alert appears within 2 seconds
- Toast notification: "Tamper Detected!"

### 2. Test Network Down

```bash
# Disconnect network
sudo ifconfig eth0 down

# Run test
./test_tamper
```

**Expected:**
- Console: "✅ Tamper logged to SQLite"
- Console: "📵 Network unavailable, will sync via anna.sh later"
- Dashboard: No immediate alert

```bash
# Reconnect network
sudo ifconfig eth0 up

# Wait for anna.sh or run manually
sudo ./anna.sh
```

**Expected:**
- Dashboard: Alert appears after sync

## Troubleshooting

### Real-time alerts not working

1. Check network: `ping google.com`
2. Check ngrok: Visit ngrok URL in browser
3. Check backend logs: Look for WebSocket emit messages
4. Check dashboard: Should show "🟢 Connected"
5. Check Luckfox logs: Should show "🚨 Real-time alert sent successfully"

### anna.sh still needed?

**YES!** It provides:
- Backup for network failures
- Historical data sync
- Guaranteed delivery
- Recovery from backend downtime

## Future Enhancements

- [ ] Retry logic with exponential backoff
- [ ] Local queue for failed alerts
- [ ] Compression for large payloads
- [ ] End-to-end encryption
- [ ] Certificate pinning
- [ ] Batching multiple alerts
- [ ] Priority levels for alerts
