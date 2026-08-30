#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error.
set -u
# Pipelines return the exit status of the last command to exit with a non-zero status.
set -o pipefail

echo "=== Sync Tamper Data to Backend Script Started ==="

# --- Configuration ---
cd "$(dirname "$0")"
echo "[INFO] Working directory: $(pwd)"

CONFIG_FILE="/home/pico/calibris/data/config.json"
DB_FILE="/home/pico/calibris/data/mydata.db"
TABLE_NAME="tamper_logs"
PRIMARY_KEY_COLUMN="log_id"
NULL_COLUMN="pushed_at"
PING_HOST="8.8.8.8"

# Backend API configuration
# Production Railway backend
API_BASE="https://calibris-fullstack-production.up.railway.app/api"
# API_KEY="your-secret-key"  # Uncomment when you add auth
MAX_RETRIES=3
TIMEOUT=10

# --- Check if config file exists ---
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[ERROR] Config file not found at $CONFIG_FILE"
    exit 1
fi
echo "[OK] Config file found"

# --- Check if database file exists ---
if [ ! -f "$DB_FILE" ]; then
    echo "[ERROR] Database file not found at $DB_FILE"
    exit 1
fi
echo "[OK] Database file found"

# --- Read Device ID and State from config.json ---
# Try to read device_id (supports both numeric and string values)
DEVICE_ID=$(grep -oP '"device_id"\s*:\s*\K[^,}\s]+' "$CONFIG_FILE" | tr -d '"' || true)
DEVICE_STATE=$(grep -oP '"state"\s*:\s*"\K[^"]+' "$CONFIG_FILE" || true)
DEVICE_TYPE=$(grep -oP '"device_type"\s*:\s*"\K[^"]+' "$CONFIG_FILE" || echo "unknown")

if [ -z "$DEVICE_ID" ]; then
    echo "[ERROR] Could not read device_id from config.json"
    echo "[INFO] Please ensure config.json has a 'device_id' field"
    exit 1
fi

if [ -z "$DEVICE_STATE" ]; then
    echo "[WARN] Could not read state from config.json, defaulting to 'Unknown'"
    DEVICE_STATE="Unknown"
fi

echo "[INFO] Device ID: $DEVICE_ID"
echo "[INFO] Device Type: $DEVICE_TYPE"
echo "[INFO] Device State: $DEVICE_STATE"
echo "[INFO] Backend API: $API_BASE"

# --- Network check function ---
check_network() { 
    ping -c 1 -W 2 "$PING_HOST" > /dev/null 2>&1
    return $?
}

# --- Escape JSON string helper ---
escape_json() {
    echo "$1" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/$/\\n/' | tr -d '\n'
}

# --- Post to backend with retries ---
post_to_backend() {
    local endpoint="$1"
    local json_data="$2"
    local attempt=1
    
    while [ $attempt -le $MAX_RETRIES ]; do
        # Uncomment next line to add auth header when ready
        # response=$(curl -s --max-time $TIMEOUT -w "\n%{http_code}" -X POST "$endpoint" -H "Content-Type: application/json" -H "X-API-Key: $API_KEY" -d "$json_data" 2>&1)
        response=$(curl -s --max-time $TIMEOUT -w "\n%{http_code}" -X POST "$endpoint" -H "Content-Type: application/json" -d "$json_data" 2>&1)
        
        # Check if curl command succeeded
        if [ $? -ne 0 ]; then
            echo "[ERROR] Attempt $attempt - Network error: $response"
            attempt=$((attempt + 1))
            [ $attempt -le $MAX_RETRIES ] && sleep 2
            continue
        fi
        
        http_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | head -n-1)
        
        if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
            echo "[OK] Posted successfully (HTTP $http_code)"
            return 0
        else
            echo "[WARN] Attempt $attempt failed (HTTP $http_code): $body"
            attempt=$((attempt + 1))
            [ $attempt -le $MAX_RETRIES ] && sleep 2
        fi
    done
    
    echo "[ERROR] Failed after $MAX_RETRIES attempts"
    return 1
}

# --- Main Logic ---

# Step 1: Check for network connectivity
echo "[INFO] Checking network connectivity..."
if ! check_network; then
    echo "[ERROR] Network connection not available. Aborting."
    exit 1
fi
echo "[OK] Network is available"

# Step 2: Register/update device info
echo "[INFO] Registering device with backend..."
DEVICE_JSON=$(cat <<EOF
{
  "device_id": "$DEVICE_ID",
  "device_type": "$DEVICE_TYPE",
  "status": "$DEVICE_STATE"
}
EOF
)

if post_to_backend "$API_BASE/devices" "$DEVICE_JSON"; then
    echo "[OK] Device registered/updated"
else
    echo "[WARN] Device registration failed, continuing with tamper sync..."
fi

# Step 3: Find unsynced tamper records
echo "[INFO] Querying database for unsynced tamper records..."
IDS_TO_PUSH=$(sqlite3 -list "$DB_FILE" "SELECT $PRIMARY_KEY_COLUMN FROM $TABLE_NAME WHERE $NULL_COLUMN IS NULL;" 2>&1) || {
    echo "[ERROR] SQLite query failed: $IDS_TO_PUSH"
    exit 1
}

if [ -z "$IDS_TO_PUSH" ]; then
    echo "[INFO] No new tamper records to push. Exiting."
    exit 0
fi

ID_LIST=$(echo "$IDS_TO_PUSH" | tr '\n' ',' | sed 's/,$//')
ROW_COUNT=$(echo "$IDS_TO_PUSH" | wc -l | xargs)
echo "[INFO] Found $ROW_COUNT tamper records to push"

# Step 4: Export and push each record
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
PUSHED_IDS=()

echo "[INFO] Pushing tamper logs to backend..."

# Export all unsynced records
sqlite3 -csv "$DB_FILE" "SELECT log_id, device_id, created_at, device_type, tamper_type, resolution_status, settling_time, renewal_cycle, latitude, longitude, city, state, drift, details, prev_hash, curr_hash FROM $TABLE_NAME WHERE $PRIMARY_KEY_COLUMN IN ($ID_LIST);" | while IFS=',' read -r log_id device_id created_at device_type tamper_type resolution_status settling_time renewal_cycle latitude longitude city state drift details prev_hash curr_hash; do
    
    # Skip header row
    [ "$log_id" = "log_id" ] && continue
    
    # Build JSON payload
    TAMPER_JSON=$(cat <<EOF
{
  "luckfox_log_id": "$log_id",
  "tamper_type": "$tamper_type",
  "severity": "$resolution_status",
  "details": "$details",
  "resolution_status": "$resolution_status",
  "settling_time": ${settling_time:-null},
  "renewal_cycle": ${renewal_cycle:-null},
  "latitude": ${latitude:-null},
  "longitude": ${longitude:-null},
  "city": "$city",
  "state": "$state",
  "drift": ${drift:-null},
  "prev_hash": "$prev_hash",
  "curr_hash": "$curr_hash",
  "event_time": "$created_at"
}
EOF
)
    
    echo "[INFO] Pushing log_id=$log_id for device=$device_id"
    
    if post_to_backend "$API_BASE/devices/$device_id/tamper" "$TAMPER_JSON"; then
        PUSHED_IDS+=("$log_id")
    else
        echo "[ERROR] Failed to push log_id=$log_id"
    fi
done

# Step 5: Mark successfully pushed records
if [ ${#PUSHED_IDS[@]} -gt 0 ]; then
    PUSHED_LIST=$(IFS=,; echo "${PUSHED_IDS[*]}")
    echo "[INFO] Marking ${#PUSHED_IDS[@]} records as pushed..."
    sqlite3 "$DB_FILE" "UPDATE $TABLE_NAME SET $NULL_COLUMN = '$TIMESTAMP' WHERE $PRIMARY_KEY_COLUMN IN ($PUSHED_LIST);"
    echo "[OK] Database updated"
else
    echo "[WARN] No records were successfully pushed"
fi

echo "=== Process completed! Pushed ${#PUSHED_IDS[@]} of $ROW_COUNT records ==="
