# Tamper Logging Library with Real-time Alerts

This library provides tamper detection logging for Luckfox devices with **real-time WebSocket alerts** to your dashboard.

## Features

✅ Logs tamper events to local SQLite database
✅ **Sends immediate alerts to dashboard when network is available**
✅ Non-blocking asynchronous HTTP requests
✅ Blockchain-style hash chain for data integrity
✅ Falls back to anna.sh batch sync if network is unavailable
✅ Thread-safe database operations

## Architecture

```
Tamper Detected
    ↓
log_tamper_realtime()
    ↓
1. Write to SQLite ✅ (always happens)
    ↓
2. Check network availability
    ↓
3a. Network Available → Send HTTP POST → Backend → WebSocket → Dashboard (real-time!)
3b. Network Down → Skip alert (anna.sh will sync later)
```

## Installation on Luckfox

### 1. Install Dependencies

```bash
# Install libcurl (for HTTP requests)
sudo apt-get update
sudo apt-get install -y libcurl4-openssl-dev

# Install OpenSSL (for SHA-256 hashing)
sudo apt-get install -y libssl-dev

# Install SQLite (usually pre-installed)
sudo apt-get install -y libsqlite3-dev
```

### 2. Copy Files to Luckfox

Copy these files to your Luckfox device:
- `tamper_logs_realtime.h`
- `tamper_logs_realtime.c`
- `example_usage.c` (optional, for testing)

```bash
# From your development machine:
scp tamper_logs_realtime.* pico@luckfox:~/calibris/
scp example_usage.c pico@luckfox:~/calibris/
```

### 3. Compile the Library

```bash
# On Luckfox device:
cd ~/calibris/

# Compile the library
gcc -c tamper_logs_realtime.c -o tamper_logs_realtime.o -lcurl -lssl -lcrypto -lsqlite3 -lpthread

# Create static library (optional)
ar rcs libtamper_realtime.a tamper_logs_realtime.o

# Compile example
gcc example_usage.c tamper_logs_realtime.o -o test_tamper -lcurl -lssl -lcrypto -lsqlite3 -lpthread
```

### 4. Test the Library

```bash
# Make sure your backend server is running with ngrok
# Update API_ENDPOINT in tamper_logs_realtime.h if needed

# Run test
./test_tamper
```

Expected output:
```
✅ Tamper logging initialized with real-time alerts
--- Example 1: Physical Tamper ---
✅ Tamper logged to SQLite: PHYSICAL_TAMPER (ID: 1)
📡 Attempting real-time alert...
🚨 Real-time alert sent successfully for PHYSICAL_TAMPER
```

## Usage in Your Code

### Replace Your Existing Library

**Old code (your current tamper_logs.c):**
```c
#include "tamper_logs.h"

// Your existing function call
log_tamper("PHYSICAL_TAMPER", "Device opened");
```

**New code (with real-time alerts):**
```c
#include "tamper_logs_realtime.h"

int main() {
    // Initialize once at startup
    init_tamper_logging("/home/pico/calibris/data/mydata.db");

    // Log tamper with real-time alert
    log_tamper_realtime(
        "PHYSICAL_TAMPER",           // tamper_type
        "Device enclosure opened",   // details
        2.5,                          // settling_time
        10,                           // renewal_cycle
        13.0827,                      // latitude
        80.2707,                      // longitude
        "Chennai",                    // city
        "Tamil Nadu",                 // state
        0.0                           // drift
    );

    // Cleanup at shutdown
    cleanup_tamper_logging();
    return 0;
}
```

### Compile Your Application

```bash
gcc your_app.c tamper_logs_realtime.o -o your_app -lcurl -lssl -lcrypto -lsqlite3 -lpthread
```

## Configuration

Edit `tamper_logs_realtime.h` to configure:

```c
// Your ngrok URL + API endpoint
#define API_ENDPOINT "https://your-ngrok-url.ngrok-free.dev/api/devices/1/tamper"

// Your device ID
#define DEVICE_ID 1

// Network timeout (milliseconds)
#define NETWORK_TIMEOUT_MS 3000
```

## How It Works

1. **Tamper Detected** → Your code calls `log_tamper_realtime()`
2. **SQLite Write** → Event saved to local database (always happens)
3. **Network Check** → Library checks if internet is available
4. **Real-time Alert** → If network available, sends HTTP POST to backend
5. **Backend Processing** → Backend receives POST, saves to PostgreSQL, emits WebSocket event
6. **Dashboard Alert** → Dashboard receives WebSocket event, shows real-time alert
7. **Backup Sync** → anna.sh continues to run periodically to sync any missed events

## Benefits

- ⚡ **Instant alerts** when network is available
- 💾 **No data loss** - all events saved to SQLite first
- 🔄 **Automatic failover** - anna.sh syncs missed events
- 🚀 **Non-blocking** - alerts sent in background thread
- 🔒 **Thread-safe** - multiple tamper events can be logged simultaneously

## Troubleshooting

### Network Check Fails
```bash
# Test network manually
curl -I https://www.google.com
```

### Compilation Errors
```bash
# Make sure all dependencies are installed
sudo apt-get install -y libcurl4-openssl-dev libssl-dev libsqlite3-dev

# Check library paths
ldconfig -p | grep curl
ldconfig -p | grep ssl
ldconfig -p | grep sqlite
```

### Alert Not Received on Dashboard
1. Check backend server is running
2. Verify ngrok URL is correct in `API_ENDPOINT`
3. Check WebSocket connection on dashboard (should show "🟢 Connected")
4. Look at Luckfox logs: `./test_tamper` should show "🚨 Real-time alert sent successfully"

## Migration from Old Library

If you're using the old `tamper_logs.c` library:

1. **Keep both libraries** - you can run them side by side
2. **Update function calls** - change `log_tamper()` to `log_tamper_realtime()`
3. **Add parameters** - new function needs more parameters (lat, lon, city, state, drift)
4. **Keep anna.sh** - it provides backup sync for network failures

## anna.sh Still Needed?

**YES!** Keep running anna.sh because:
- Network might be down when tamper occurs
- HTTP request might timeout or fail
- Provides guaranteed delivery
- Handles historical data sync

Think of it as:
- **Real-time alerts** = Primary system (fast but may fail)
- **anna.sh** = Backup system (slower but guaranteed)

## Next Steps

1. Copy files to your Luckfox device
2. Compile the library
3. Test with `./test_tamper`
4. Check dashboard for real-time alerts
5. Integrate into your main application
6. Keep anna.sh running as backup
