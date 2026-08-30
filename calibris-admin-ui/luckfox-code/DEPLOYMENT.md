# Deployment Guide: Real-time Tamper Alerts

## Quick Start (15 minutes)

### Step 1: Prepare Backend (Your Computer)

```bash
# Navigate to project
cd "c:\Users\deepa\Desktop\calabris software\Calibris-software"

# Make sure backend is running
npm run dev
# Should show: "🚀 Backend API server running on port 3000"

# In a new terminal, start ngrok
ngrok http 3000
# Copy the HTTPS URL (e.g., https://abc123.ngrok-free.dev)
```

### Step 2: Transfer Files to Luckfox

```bash
# From your computer (Git Bash or WSL):
cd "c:\Users\deepa\Desktop\calabris software\Calibris-software\luckfox-code"

# Transfer files
scp tamper_logs_realtime.h pico@<LUCKFOX_IP>:~/calibris/
scp tamper_logs_realtime.c pico@<LUCKFOX_IP>:~/calibris/
scp example_usage.c pico@<LUCKFOX_IP>:~/calibris/
scp Makefile pico@<LUCKFOX_IP>:~/calibris/
scp install.sh pico@<LUCKFOX_IP>:~/calibris/
```

### Step 3: Configure on Luckfox

```bash
# SSH into Luckfox
ssh pico@<LUCKFOX_IP>

# Navigate to directory
cd ~/calibris/

# Edit configuration (update your ngrok URL)
nano tamper_logs_realtime.h
```

**Update line 7:**
```c
#define API_ENDPOINT "https://YOUR-NGROK-URL.ngrok-free.dev/api/devices/1/tamper"
```

Save and exit (Ctrl+X, Y, Enter)

### Step 4: Install and Test

```bash
# Make install script executable
chmod +x install.sh

# Run installer
./install.sh

# After successful installation, test it
./test_tamper
```

**Expected output:**
```
✅ Tamper logging initialized with real-time alerts
--- Example 1: Physical Tamper ---
✅ Tamper logged to SQLite: PHYSICAL_TAMPER (ID: 1)
📡 Attempting real-time alert...
🚨 Real-time alert sent successfully for PHYSICAL_TAMPER
```

### Step 5: Check Dashboard

Open your browser to: `http://localhost:5173`

You should see:
- "🟢 Connected" badge (WebSocket active)
- Latest alert displayed in red box
- Alert history showing test events
- Toast notification appeared

## Integration into Your Application

### Option 1: Replace Existing Library

If you have existing code using `tamper_logs.c`:

**Old code:**
```c
#include "tamper_logs.h"

void detect_tamper() {
    log_tamper("PHYSICAL_TAMPER", "Device opened");
}
```

**New code:**
```c
#include "tamper_logs_realtime.h"

// Initialize once at startup
int main() {
    init_tamper_logging("/home/pico/calibris/data/mydata.db");

    // ... your code ...

    cleanup_tamper_logging();
    return 0;
}

void detect_tamper() {
    log_tamper_realtime(
        "PHYSICAL_TAMPER",       // tamper_type
        "Device opened",          // details
        2.5,                      // settling_time
        10,                       // renewal_cycle
        13.0827,                  // latitude (get from GPS)
        80.2707,                  // longitude
        "Chennai",                // city
        "Tamil Nadu",             // state
        0.0                       // drift (0 for physical tamper)
    );
}
```

### Option 2: Use Alongside Existing Library

Keep both libraries running:

```c
#include "tamper_logs.h"           // Your existing library
#include "tamper_logs_realtime.h"  // New real-time library

int main() {
    // Initialize both
    init_tamper_logging("/home/pico/calibris/data/mydata.db");

    // ... your application ...

    cleanup_tamper_logging();
    return 0;
}

void detect_tamper() {
    // Use only the new real-time library
    // (it already logs to SQLite + sends real-time alert)
    log_tamper_realtime(
        "PHYSICAL_TAMPER",
        "Device opened",
        2.5, 10,
        13.0827, 80.2707,
        "Chennai", "Tamil Nadu",
        0.0
    );
}
```

### Compilation

```bash
# Compile your application
gcc your_app.c tamper_logs_realtime.o -o your_app \
    -lcurl -lssl -lcrypto -lsqlite3 -lpthread

# Or use the static library
gcc your_app.c -L. -ltamper_realtime -o your_app \
    -lcurl -lssl -lcrypto -lsqlite3 -lpthread
```

## Production Deployment

### 1. Update API Endpoint for Production

When you deploy your backend to a real server (not ngrok):

**In `tamper_logs_realtime.h`:**
```c
// Change from ngrok URL:
// #define API_ENDPOINT "https://abc123.ngrok-free.dev/api/devices/1/tamper"

// To production URL:
#define API_ENDPOINT "https://your-domain.com/api/devices/1/tamper"
```

Recompile:
```bash
make clean
make
```

### 2. Set Up Systemd Service (Optional)

Create a systemd service for your application:

```bash
sudo nano /etc/systemd/system/tamper-monitor.service
```

**Content:**
```ini
[Unit]
Description=Tamper Detection Monitor
After=network.target

[Service]
Type=simple
User=pico
WorkingDirectory=/home/pico/calibris
ExecStart=/home/pico/calibris/your_app
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable tamper-monitor
sudo systemctl start tamper-monitor
sudo systemctl status tamper-monitor
```

### 3. Keep anna.sh Running

Even with real-time alerts, keep anna.sh as backup:

```bash
# Check crontab
crontab -l

# Should show:
# */5 * * * * /home/pico/calibris/auto_update/anna.sh >> /home/pico/calibris/auto_update/sync.log 2>&1
```

## Monitoring and Logs

### Check Luckfox Logs

```bash
# View real-time logs (if using systemd)
sudo journalctl -u tamper-monitor -f

# View anna.sh sync logs
tail -f ~/calibris/auto_update/sync.log

# Check SQLite database
sqlite3 /home/pico/calibris/data/mydata.db "SELECT * FROM tamper_logs ORDER BY log_id DESC LIMIT 10;"
```

### Check Backend Logs

```bash
# Backend should show:
# ⚠️ TAMPER ALERT: Device 1 - Broadcasting to dashboard
# 🚨 Broadcasting tamper alert: 1
```

### Check Dashboard

- Connection status: Should show "🟢 Connected"
- Latest alert: Should update within 2 seconds
- Alert history: Should accumulate new alerts
- Toast notifications: Should appear for each alert

## Troubleshooting

### Problem: "Failed to initialize cURL"

**Solution:**
```bash
# Install libcurl
sudo apt-get install -y libcurl4-openssl-dev

# Recompile
make clean
make
```

### Problem: "Network unavailable" (but network is working)

**Solution:**
```bash
# Test network manually
ping google.com

# Test cURL
curl -I https://google.com

# Check DNS
cat /etc/resolv.conf

# Try manual POST
curl -X POST https://your-ngrok-url.ngrok-free.dev/api/devices/1/tamper \
  -H "Content-Type: application/json" \
  -d '{"tamper_type":"TEST","details":"Manual test"}'
```

### Problem: Dashboard not receiving alerts

**Check WebSocket connection:**
1. Open browser DevTools (F12)
2. Go to Network tab
3. Filter: WS (WebSocket)
4. Should see connection to `ws://localhost:3000`

**Backend should show:**
```
✅ Client connected: abc123
```

### Problem: Duplicate alerts

**Solution:**
This is normal if:
1. Real-time alert succeeds
2. anna.sh runs later and syncs same event

The duplicate prevention in anna.sh only prevents duplicate POSTs from anna.sh itself, not from the C library.

To fix, modify backend to check for duplicates based on `luckfox_log_id` or `curr_hash`.

## Performance Tuning

### Adjust Network Timeout

Edit `tamper_logs_realtime.h`:

```c
// Default: 3 seconds
#define NETWORK_TIMEOUT_MS 3000

// For faster failure detection (more aggressive):
#define NETWORK_TIMEOUT_MS 1000

// For slower/unstable networks:
#define NETWORK_TIMEOUT_MS 5000
```

### Adjust anna.sh Frequency

```bash
# Edit crontab
crontab -e

# More frequent (every 2 minutes):
*/2 * * * * /home/pico/calibris/auto_update/anna.sh >> /home/pico/calibris/auto_update/sync.log 2>&1

# Less frequent (every 10 minutes):
*/10 * * * * /home/pico/calibris/auto_update/anna.sh >> /home/pico/calibris/auto_update/sync.log 2>&1
```

## Security Considerations

### 1. HTTPS Only

Always use HTTPS for API endpoint (never HTTP):
```c
#define API_ENDPOINT "https://..."  // ✅ Good
#define API_ENDPOINT "http://..."   // ❌ Bad
```

### 2. API Authentication (Future)

Add authentication token:

```c
// In send_tamper_alert() function:
headers = curl_slist_append(headers, "Authorization: Bearer YOUR_TOKEN");
```

### 3. Certificate Verification

The library uses system CA certificates by default. To pin certificates:

```c
curl_easy_setopt(curl, CURLOPT_CAINFO, "/path/to/ca-bundle.crt");
```

## Next Steps

1. ✅ Test in development (ngrok)
2. ✅ Integrate into your application
3. ✅ Deploy backend to production server
4. ✅ Update API_ENDPOINT to production URL
5. ✅ Set up systemd service
6. ✅ Monitor logs
7. ✅ Add authentication (optional)
8. ✅ Set up SSL certificate pinning (optional)

## Support

If you encounter issues:

1. Check ARCHITECTURE.md for system overview
2. Check README.md for usage examples
3. Review logs on Luckfox and backend
4. Test network connectivity
5. Verify API endpoint configuration

## Summary

You now have a **hybrid system**:

- **Real-time alerts** (~1 second latency) when network available
- **Batch sync** (5-minute intervals) as backup
- **Local persistence** (SQLite) prevents data loss
- **Cloud storage** (PostgreSQL) for historical analysis
- **Dashboard notifications** (WebSocket + Toast)

This provides the best of both worlds: speed when possible, reliability always.
