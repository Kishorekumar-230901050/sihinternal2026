// tamper_logs_realtime.c
// Enhanced tamper logging with real-time alerts

#include "tamper_logs_realtime.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sqlite3.h>
#include <curl/curl.h>
#include <openssl/sha.h>
#include <pthread.h>

static sqlite3* db = NULL;
static char last_hash[65] = {0};
static pthread_mutex_t db_mutex = PTHREAD_MUTEX_INITIALIZER;

// Callback for cURL (discards response body)
static size_t write_callback(void* contents, size_t size, size_t nmemb, void* userp) {
    return size * nmemb;
}

// Initialize database
int init_tamper_logging(const char* db_path) {
    int rc = sqlite3_open(db_path, &db);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "Failed to open database: %s\n", sqlite3_errmsg(db));
        return -1;
    }

    // Create table if not exists (matches your existing schema)
    const char* create_table_sql =
        "CREATE TABLE IF NOT EXISTS tamper_logs ("
        "log_id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "device_id INTEGER NOT NULL,"
        "created_at TEXT DEFAULT (datetime('now')),"
        "device_type TEXT,"
        "tamper_type TEXT NOT NULL,"
        "details TEXT,"
        "settling_time REAL,"
        "renewal_cycle INTEGER,"
        "latitude REAL,"
        "longitude REAL,"
        "city TEXT,"
        "state TEXT,"
        "drift REAL,"
        "prev_hash TEXT,"
        "curr_hash TEXT"
        ");";

    char* err_msg = NULL;
    rc = sqlite3_exec(db, create_table_sql, NULL, NULL, &err_msg);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "Failed to create table: %s\n", err_msg);
        sqlite3_free(err_msg);
        return -1;
    }

    // Initialize cURL globally
    curl_global_init(CURL_GLOBAL_DEFAULT);

    printf("✅ Tamper logging initialized with real-time alerts\n");
    return 0;
}

// Calculate SHA256 hash for blockchain
static void calculate_hash(const TamperLog* log, char* output) {
    unsigned char hash[SHA256_DIGEST_LENGTH];
    SHA256_CTX sha256;
    SHA256_Init(&sha256);

    // Hash the log data
    char buffer[1024];
    snprintf(buffer, sizeof(buffer), "%d%s%s%s%.2f%d%.6f%.6f%s%s%.3f%s",
        log->device_id, log->created_at, log->device_type, log->tamper_type,
        log->settling_time, log->renewal_cycle, log->latitude, log->longitude,
        log->city, log->state, log->drift, log->prev_hash);

    SHA256_Update(&sha256, buffer, strlen(buffer));
    SHA256_Final(hash, &sha256);

    // Convert to hex string
    for (int i = 0; i < SHA256_DIGEST_LENGTH; i++) {
        sprintf(output + (i * 2), "%02x", hash[i]);
    }
    output[64] = '\0';
}

// Check if network is available
int check_network_available() {
    // Quick check: try to resolve DNS
    CURL* curl = curl_easy_init();
    if (!curl) return 0;

    curl_easy_setopt(curl, CURLOPT_URL, "https://www.google.com");
    curl_easy_setopt(curl, CURLOPT_NOBODY, 1L);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT_MS, 1000L);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);

    CURLcode res = curl_easy_perform(curl);
    curl_easy_cleanup(curl);

    return (res == CURLE_OK) ? 1 : 0;
}

// Send tamper alert to backend via HTTP POST
int send_tamper_alert(const TamperLog* log) {
    CURL* curl = curl_easy_init();
    if (!curl) {
        fprintf(stderr, "❌ Failed to initialize cURL\n");
        return -1;
    }

    // Build JSON payload
    char json_payload[2048];
    snprintf(json_payload, sizeof(json_payload),
        "{"
        "\"device_type\":\"%s\","
        "\"tamper_type\":\"%s\","
        "\"details\":\"%s\","
        "\"settling_time\":%.2f,"
        "\"renewal_cycle\":%d,"
        "\"latitude\":%.6f,"
        "\"longitude\":%.6f,"
        "\"city\":\"%s\","
        "\"state\":\"%s\","
        "\"drift\":%.3f,"
        "\"prev_hash\":\"%s\","
        "\"curr_hash\":\"%s\""
        "}",
        log->device_type, log->tamper_type, log->details,
        log->settling_time, log->renewal_cycle,
        log->latitude, log->longitude,
        log->city, log->state, log->drift,
        log->prev_hash, log->curr_hash
    );

    struct curl_slist* headers = NULL;
    headers = curl_slist_append(headers, "Content-Type: application/json");

    curl_easy_setopt(curl, CURLOPT_URL, API_ENDPOINT);
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, json_payload);
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT_MS, NETWORK_TIMEOUT_MS);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);

    CURLcode res = curl_easy_perform(curl);

    if (res == CURLE_OK) {
        long http_code = 0;
        curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_code);

        if (http_code == 201 || http_code == 200) {
            printf("🚨 Real-time alert sent successfully for %s\n", log->tamper_type);
            curl_slist_free_all(headers);
            curl_easy_cleanup(curl);
            return 0;
        } else {
            fprintf(stderr, "⚠️ Alert sent but got HTTP %ld\n", http_code);
        }
    } else {
        fprintf(stderr, "⚠️ Network unavailable, alert will sync via anna.sh: %s\n",
                curl_easy_strerror(res));
    }

    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);
    return -1;
}

// Thread function to send alert asynchronously
typedef struct {
    TamperLog log;
} AlertThreadData;

static void* send_alert_thread(void* arg) {
    AlertThreadData* data = (AlertThreadData*)arg;
    send_tamper_alert(&data->log);
    free(data);
    return NULL;
}

// Log tamper event with real-time alert
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
) {
    if (!db) {
        fprintf(stderr, "❌ Database not initialized\n");
        return -1;
    }

    pthread_mutex_lock(&db_mutex);

    // Create tamper log
    TamperLog log;
    log.device_id = DEVICE_ID;
    time_t now = time(NULL);
    struct tm* tm_info = localtime(&now);
    strftime(log.created_at, sizeof(log.created_at), "%Y-%m-%d %H:%M:%S", tm_info);

    strncpy(log.device_type, "Luckfox Pico", sizeof(log.device_type) - 1);
    strncpy(log.tamper_type, tamper_type, sizeof(log.tamper_type) - 1);
    strncpy(log.details, details, sizeof(log.details) - 1);
    log.settling_time = settling_time;
    log.renewal_cycle = renewal_cycle;
    log.latitude = latitude;
    log.longitude = longitude;
    strncpy(log.city, city, sizeof(log.city) - 1);
    strncpy(log.state, state, sizeof(log.state) - 1);
    log.drift = drift;

    // Blockchain hashing
    strncpy(log.prev_hash, last_hash, sizeof(log.prev_hash) - 1);
    calculate_hash(&log, log.curr_hash);
    strncpy(last_hash, log.curr_hash, sizeof(last_hash) - 1);

    // Insert into SQLite database
    const char* insert_sql =
        "INSERT INTO tamper_logs (device_id, created_at, device_type, tamper_type, "
        "details, settling_time, renewal_cycle, latitude, longitude, city, state, "
        "drift, prev_hash, curr_hash) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

    sqlite3_stmt* stmt;
    int rc = sqlite3_prepare_v2(db, insert_sql, -1, &stmt, NULL);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "❌ Failed to prepare statement: %s\n", sqlite3_errmsg(db));
        pthread_mutex_unlock(&db_mutex);
        return -1;
    }

    sqlite3_bind_int(stmt, 1, log.device_id);
    sqlite3_bind_text(stmt, 2, log.created_at, -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 3, log.device_type, -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 4, log.tamper_type, -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 5, log.details, -1, SQLITE_STATIC);
    sqlite3_bind_double(stmt, 6, log.settling_time);
    sqlite3_bind_int(stmt, 7, log.renewal_cycle);
    sqlite3_bind_double(stmt, 8, log.latitude);
    sqlite3_bind_double(stmt, 9, log.longitude);
    sqlite3_bind_text(stmt, 10, log.city, -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 11, log.state, -1, SQLITE_STATIC);
    sqlite3_bind_double(stmt, 12, log.drift);
    sqlite3_bind_text(stmt, 13, log.prev_hash, -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 14, log.curr_hash, -1, SQLITE_STATIC);

    rc = sqlite3_step(stmt);
    if (rc != SQLITE_DONE) {
        fprintf(stderr, "❌ Failed to insert tamper log: %s\n", sqlite3_errmsg(db));
        sqlite3_finalize(stmt);
        pthread_mutex_unlock(&db_mutex);
        return -1;
    }

    log.log_id = sqlite3_last_insert_rowid(db);
    sqlite3_finalize(stmt);
    pthread_mutex_unlock(&db_mutex);

    printf("✅ Tamper logged to SQLite: %s (ID: %d)\n", tamper_type, log.log_id);

    // Send real-time alert in background thread (non-blocking)
    if (check_network_available()) {
        AlertThreadData* thread_data = malloc(sizeof(AlertThreadData));
        if (thread_data) {
            memcpy(&thread_data->log, &log, sizeof(TamperLog));

            pthread_t thread;
            if (pthread_create(&thread, NULL, send_alert_thread, thread_data) == 0) {
                pthread_detach(thread);  // Let it run independently
                printf("📡 Attempting real-time alert...\n");
            } else {
                free(thread_data);
                fprintf(stderr, "⚠️ Failed to create alert thread\n");
            }
        }
    } else {
        printf("📵 Network unavailable, will sync via anna.sh later\n");
    }

    return log.log_id;
}

// Cleanup
void cleanup_tamper_logging() {
    if (db) {
        sqlite3_close(db);
        db = NULL;
    }
    curl_global_cleanup();
    printf("✅ Tamper logging cleaned up\n");
}
