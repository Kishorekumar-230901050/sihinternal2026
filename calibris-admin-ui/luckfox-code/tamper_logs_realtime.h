// tamper_logs_realtime.h
// Enhanced tamper logging with real-time alerts

#ifndef TAMPER_LOGS_REALTIME_H
#define TAMPER_LOGS_REALTIME_H

#include <time.h>

// Configuration
#define API_ENDPOINT "https://unexploratory-harland-nontemporizingly.ngrok-free.dev/api/devices/1/tamper"
#define DEVICE_ID 1
#define NETWORK_TIMEOUT_MS 3000  // 3 second timeout for HTTP requests

// Tamper log structure
typedef struct {
    int log_id;
    int device_id;
    char created_at[32];
    char device_type[64];
    char tamper_type[64];
    char details[256];
    double settling_time;
    int renewal_cycle;
    double latitude;
    double longitude;
    char city[128];
    char state[128];
    double drift;
    char prev_hash[65];
    char curr_hash[65];
} TamperLog;

// Initialize tamper logging system
int init_tamper_logging(const char* db_path);

// Log tamper event (writes to SQLite + sends real-time alert if network available)
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

// Send tamper alert to backend (called automatically by log_tamper_realtime)
int send_tamper_alert(const TamperLog* log);

// Check if network is available
int check_network_available();

// Cleanup
void cleanup_tamper_logging();

#endif // TAMPER_LOGS_REALTIME_H
