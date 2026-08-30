// example_usage.c
// Example of how to use the real-time tamper logging library

#include "tamper_logs_realtime.h"
#include <stdio.h>
#include <unistd.h>

int main() {
    // Initialize the tamper logging system
    if (init_tamper_logging("/home/pico/calibris/data/mydata.db") != 0) {
        fprintf(stderr, "Failed to initialize tamper logging\n");
        return 1;
    }

    printf("Tamper logging system initialized\n");

    // Example 1: Physical tamper detected
    printf("\n--- Example 1: Physical Tamper ---\n");
    log_tamper_realtime(
        "PHYSICAL_TAMPER",           // tamper_type
        "Device enclosure opened",    // details
        2.5,                          // settling_time (seconds)
        10,                           // renewal_cycle
        13.0827,                      // latitude
        80.2707,                      // longitude
        "Chennai",                    // city
        "Tamil Nadu",                 // state
        0.0                           // drift (not applicable for physical tamper)
    );

    sleep(2);  // Wait 2 seconds

    // Example 2: Temperature drift detected
    printf("\n--- Example 2: Temperature Drift ---\n");
    log_tamper_realtime(
        "TEMPERATURE_DRIFT",
        "Temperature exceeded threshold: 45.2°C",
        3.0,
        15,
        13.0827,
        80.2707,
        "Chennai",
        "Tamil Nadu",
        5.2  // drift value in degrees
    );

    sleep(2);

    // Example 3: Accelerometer tamper
    printf("\n--- Example 3: Accelerometer Tamper ---\n");
    log_tamper_realtime(
        "ACCELEROMETER_TAMPER",
        "Sudden movement detected",
        1.5,
        5,
        13.0827,
        80.2707,
        "Chennai",
        "Tamil Nadu",
        0.0
    );

    sleep(2);

    // Example 4: Hash verification failure
    printf("\n--- Example 4: Hash Verification Failure ---\n");
    log_tamper_realtime(
        "HASH_VERIFICATION_FAILURE",
        "Data integrity compromised",
        0.5,
        20,
        13.0827,
        80.2707,
        "Chennai",
        "Tamil Nadu",
        0.0
    );

    // Cleanup
    cleanup_tamper_logging();

    printf("\n✅ All tamper events logged successfully\n");
    printf("📡 Real-time alerts sent (if network available)\n");
    printf("💾 All events saved to SQLite (anna.sh will sync any missed)\n");

    return 0;
}
