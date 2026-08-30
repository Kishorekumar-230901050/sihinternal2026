# Migration Guide: From tamper_logs.c to tamper_logs_realtime.c

## What's Different?

### Old Library (tamper_logs.c)
- ✅ Logs to SQLite only
- ✅ Uses blockchain hash chain
- ✅ Simple function: `log_tamper(type, details)`
- ❌ No network capability
- ❌ No real-time alerts
- ❌ Depends on anna.sh for all syncing

### New Library (tamper_logs_realtime.c)
- ✅ Logs to SQLite (same as before)
- ✅ Uses blockchain hash chain (same as before)
- ✅ **Sends real-time alerts via HTTP**
- ✅ **Non-blocking network requests**
- ✅ **1-second alert latency**
- ✅ Still works with anna.sh as backup
- ✅ Gracefully handles network failures

## Side-by-Side Comparison

### Function Signatures

**Old:**
```c
int log_tamper(const char* tamper_type, const char* details);
```

**New:**
```c
int log_tamper_realtime(
    const char* tamper_type,
    const char* details,
    double settling_time,
    int renewal_cycle,
    double latitude,
    double longitude,
    const char* city,
    const char* state,
    double drift
);
```

### Initialization

**Old:**
```c
// No explicit initialization needed
// Just call log_tamper()
```

**New:**
```c
// Initialize once at startup
init_tamper_logging("/home/pico/calibris/data/mydata.db");

// ... your code ...

// Cleanup at shutdown
cleanup_tamper_logging();
```

### Usage Example

**Old code:**
```c
#include "tamper_logs.h"

int main() {
    // Detect physical tamper
    log_tamper("PHYSICAL_TAMPER", "Device enclosure opened");

    // Detect temperature drift
    log_tamper("TEMPERATURE_DRIFT", "Temp exceeded 45°C");

    return 0;
}
```

**New code:**
```c
#include "tamper_logs_realtime.h"

int main() {
    // Initialize
    init_tamper_logging("/home/pico/calibris/data/mydata.db");

    // Detect physical tamper (with location data)
    log_tamper_realtime(
        "PHYSICAL_TAMPER",
        "Device enclosure opened",
        2.5,          // settling_time (seconds)
        10,           // renewal_cycle
        13.0827,      // latitude
        80.2707,      // longitude
        "Chennai",    // city
        "Tamil Nadu", // state
        0.0           // drift (n/a for physical)
    );

    // Detect temperature drift
    log_tamper_realtime(
        "TEMPERATURE_DRIFT",
        "Temp exceeded 45°C",
        3.0,          // settling_time
        15,           // renewal_cycle
        13.0827,      // latitude
        80.2707,      // longitude
        "Chennai",    // city
        "Tamil Nadu", // state
        5.2           // drift (5.2°C over threshold)
    );

    // Cleanup
    cleanup_tamper_logging();
    return 0;
}
```

## Migration Steps

### Step 1: Backup Your Current Code

```bash
# Backup your current implementation
cp your_app.c your_app.c.backup
cp tamper_logs.c tamper_logs.c.backup
cp tamper_logs.h tamper_logs.h.backup
```

### Step 2: Add New Files (Don't Delete Old Ones)

```bash
# Copy new library files
# Keep your old files intact
ls -la
# Should show:
# tamper_logs.c (old)
# tamper_logs.h (old)
# tamper_logs_realtime.c (new)
# tamper_logs_realtime.h (new)
```

### Step 3: Update Your Code

#### Option A: Minimal Changes (Wrapper Function)

Create a wrapper to keep your old function signature:

```c
// your_app.c
#include "tamper_logs_realtime.h"

// Wrapper function - same signature as old log_tamper()
int log_tamper(const char* tamper_type, const char* details) {
    // Default values for new parameters
    return log_tamper_realtime(
        tamper_type,
        details,
        2.0,          // default settling_time
        10,           // default renewal_cycle
        13.0827,      // TODO: Get from GPS
        80.2707,      // TODO: Get from GPS
        "Chennai",    // TODO: Get from location service
        "Tamil Nadu", // TODO: Get from location service
        0.0           // default drift
    );
}

int main() {
    init_tamper_logging("/home/pico/calibris/data/mydata.db");

    // Your existing code works unchanged!
    log_tamper("PHYSICAL_TAMPER", "Device opened");
    log_tamper("TEMPERATURE_DRIFT", "Temp too high");

    cleanup_tamper_logging();
    return 0;
}
```

#### Option B: Full Migration (Recommended)

Update all calls to use the new function:

```c
// your_app.c
#include "tamper_logs_realtime.h"

// Global variables (get from GPS/config)
#define DEVICE_LAT 13.0827
#define DEVICE_LON 80.2707
#define DEVICE_CITY "Chennai"
#define DEVICE_STATE "Tamil Nadu"

int main() {
    init_tamper_logging("/home/pico/calibris/data/mydata.db");

    // Update all calls to new function
    log_tamper_realtime(
        "PHYSICAL_TAMPER",
        "Device opened",
        2.5, 10,
        DEVICE_LAT, DEVICE_LON,
        DEVICE_CITY, DEVICE_STATE,
        0.0
    );

    cleanup_tamper_logging();
    return 0;
}
```

### Step 4: Update Compilation

**Old compilation:**
```bash
gcc your_app.c tamper_logs.c -o your_app -lsqlite3 -lssl -lcrypto
```

**New compilation:**
```bash
gcc your_app.c tamper_logs_realtime.c -o your_app \
    -lsqlite3 -lssl -lcrypto -lcurl -lpthread
```

Note the two new libraries:
- `-lcurl` (for HTTP requests)
- `-lpthread` (for background threads)

### Step 5: Configure API Endpoint

Edit `tamper_logs_realtime.h`:

```c
#define API_ENDPOINT "https://your-ngrok-url.ngrok-free.dev/api/devices/1/tamper"
#define DEVICE_ID 1
```

### Step 6: Test

```bash
# Run your application
./your_app

# Check output
# Should see:
# ✅ Tamper logged to SQLite: PHYSICAL_TAMPER (ID: 1)
# 📡 Attempting real-time alert...
# 🚨 Real-time alert sent successfully

# Check dashboard - alert should appear within 2 seconds
```

## Handling Location Data

### Option 1: Static Location (Simple)

If your device doesn't move:

```c
#define DEVICE_LAT 13.0827
#define DEVICE_LON 80.2707
#define DEVICE_CITY "Chennai"
#define DEVICE_STATE "Tamil Nadu"

log_tamper_realtime(
    tamper_type, details,
    settling_time, renewal_cycle,
    DEVICE_LAT, DEVICE_LON,
    DEVICE_CITY, DEVICE_STATE,
    drift
);
```

### Option 2: GPS Integration (Advanced)

If you have GPS:

```c
#include <gps.h>  // Your GPS library

typedef struct {
    double lat;
    double lon;
    char city[128];
    char state[128];
} Location;

Location get_current_location() {
    Location loc;
    // TODO: Read from GPS module
    loc.lat = gps_get_latitude();
    loc.lon = gps_get_longitude();
    // TODO: Reverse geocoding for city/state
    strncpy(loc.city, "Chennai", sizeof(loc.city));
    strncpy(loc.state, "Tamil Nadu", sizeof(loc.state));
    return loc;
}

void detect_tamper() {
    Location loc = get_current_location();

    log_tamper_realtime(
        "PHYSICAL_TAMPER",
        "Device moved",
        2.5, 10,
        loc.lat, loc.lon,
        loc.city, loc.state,
        0.0
    );
}
```

### Option 3: Config File

Store location in a config file:

```c
// location.conf
// lat=13.0827
// lon=80.2707
// city=Chennai
// state=Tamil Nadu

Location load_location_config() {
    Location loc;
    FILE* f = fopen("/etc/calibris/location.conf", "r");
    if (f) {
        fscanf(f, "lat=%lf\n", &loc.lat);
        fscanf(f, "lon=%lf\n", &loc.lon);
        fscanf(f, "city=%s\n", loc.city);
        fscanf(f, "state=%s\n", loc.state);
        fclose(f);
    }
    return loc;
}
```

## Common Migration Issues

### Issue 1: Missing libcurl

**Error:**
```
undefined reference to 'curl_easy_init'
```

**Solution:**
```bash
sudo apt-get install -y libcurl4-openssl-dev
gcc your_app.c tamper_logs_realtime.c -o your_app -lcurl ...
```

### Issue 2: Missing pthread

**Error:**
```
undefined reference to 'pthread_create'
```

**Solution:**
```bash
gcc your_app.c tamper_logs_realtime.c -o your_app ... -lpthread
```

### Issue 3: Too Many Parameters

**Error:**
You find `log_tamper_realtime()` has too many parameters.

**Solution:**
Use the wrapper function approach (Option A above) or create a struct:

```c
typedef struct {
    const char* tamper_type;
    const char* details;
    double settling_time;
    int renewal_cycle;
    double latitude;
    double longitude;
    const char* city;
    const char* state;
    double drift;
} TamperEvent;

int log_tamper_struct(TamperEvent* event) {
    return log_tamper_realtime(
        event->tamper_type,
        event->details,
        event->settling_time,
        event->renewal_cycle,
        event->latitude,
        event->longitude,
        event->city,
        event->state,
        event->drift
    );
}

// Usage:
TamperEvent event = {
    .tamper_type = "PHYSICAL_TAMPER",
    .details = "Device opened",
    .settling_time = 2.5,
    .renewal_cycle = 10,
    .latitude = 13.0827,
    .longitude = 80.2707,
    .city = "Chennai",
    .state = "Tamil Nadu",
    .drift = 0.0
};
log_tamper_struct(&event);
```

## Rollback Plan

If something goes wrong, you can easily rollback:

### Step 1: Restore Old Code

```bash
cp your_app.c.backup your_app.c
```

### Step 2: Recompile with Old Library

```bash
gcc your_app.c tamper_logs.c -o your_app -lsqlite3 -lssl -lcrypto
```

### Step 3: Test

```bash
./your_app
# Should work exactly as before
```

## Testing Checklist

After migration, test:

- [ ] Application compiles without errors
- [ ] Application runs without crashes
- [ ] SQLite logging still works (check database)
- [ ] Network check works (test with network up/down)
- [ ] Real-time alerts appear on dashboard
- [ ] Toast notifications show up
- [ ] anna.sh still works as backup
- [ ] No duplicate entries in database
- [ ] Blockchain hash chain is valid
- [ ] Performance is acceptable

## Performance Comparison

| Metric | Old Library | New Library |
|--------|-------------|-------------|
| SQLite write | ~50ms | ~50ms (same) |
| Total blocking time | ~50ms | ~150ms* |
| Alert latency | 5 minutes (anna.sh) | **1 second** |
| Network failure handling | ❌ | ✅ |
| CPU usage | Very low | Low |
| Memory usage | ~100KB | ~500KB |

\* Network check + thread spawn. Actual HTTP request is non-blocking.

## Compatibility

| Feature | Old Library | New Library |
|---------|-------------|-------------|
| SQLite database | ✅ Same schema | ✅ Same schema |
| Hash chain | ✅ Compatible | ✅ Compatible |
| anna.sh sync | ✅ Works | ✅ Works |
| Existing data | ✅ No migration needed | ✅ No migration needed |

## Summary

**Key Benefits of Migration:**

1. ⚡ **1-second alerts** instead of 5-minute delay
2. 📊 **Better user experience** with real-time dashboard
3. 🔄 **Same reliability** - anna.sh still runs as backup
4. 💾 **No data loss** - SQLite always saves first
5. 🚀 **Non-blocking** - doesn't slow down your application
6. 🔒 **Safe migration** - both libraries can coexist

**What Stays the Same:**

1. ✅ SQLite database schema
2. ✅ Blockchain hash chain
3. ✅ Data integrity
4. ✅ anna.sh backup sync
5. ✅ Existing data (no migration needed)

**What Changes:**

1. ➕ More parameters in function call
2. ➕ Need to initialize/cleanup
3. ➕ Two new library dependencies (libcurl, pthread)
4. ➕ Configuration needed (API endpoint)

The migration is **safe, reversible, and beneficial**. You get real-time alerts while keeping all existing functionality!
