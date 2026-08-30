#!/bin/bash
# Luckfox Remote Unlock Script
# Checks backend API for pending unlock commands
# Run every 60 seconds via cron to check for unlock commands

# For LOCAL testing: Use localhost or ngrok URL
# API_BASE="http://localhost:3000/api"
# API_BASE="https://your-ngrok-url.ngrok.io/api"

# For PRODUCTION: Use Railway URL
API_BASE="https://calibris-fullstack-production.up.railway.app/api"

DEVICE_ID=1  # Change to 2 for device 2
CONFIG_FILE="/home/pico/calibris/data/config.json"
LOG_FILE="/home/pico/calibris/data/unlock.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to check for unlock command
check_unlock() {
    # Call API to check for pending unlock
    RESPONSE=$(curl -s --max-time 10 "$API_BASE/devices/$DEVICE_ID/unlock-status")

    if [ $? -ne 0 ]; then
        log_message "ERROR: Failed to contact API"
        return 1
    fi

    # Check if unlock is pending
    UNLOCK_PENDING=$(echo "$RESPONSE" | grep -o '"unlock_pending":true')

    if [ -n "$UNLOCK_PENDING" ]; then
        # Extract command_id
        COMMAND_ID=$(echo "$RESPONSE" | grep -oP '"command_id":\K[0-9]+')
        OFFICER=$(echo "$RESPONSE" | grep -oP '"officer_id":"\K[^"]+')

        log_message "🔓 Unlock command received (Command ID: $COMMAND_ID, Officer: $OFFICER)"

        # Perform unlock
        perform_unlock "$COMMAND_ID"
    fi
}

# Function to perform the unlock
perform_unlock() {
    local COMMAND_ID=$1

    log_message "Starting unlock process..."

    # Step 1: Update config.json to disable safe mode
    if [ -f "$CONFIG_FILE" ]; then
        # Use sed to update safe_mode to false
        sed -i 's/"safe_mode":\s*true/"safe_mode": false/g' "$CONFIG_FILE"
        log_message "✓ Updated config.json (safe_mode = false)"
    else
        log_message "WARN: Config file not found at $CONFIG_FILE"
    fi

    # Step 2: Stop safe mode service (if running)
    if systemctl is-active --quiet safe_mode.service; then
        systemctl stop safe_mode.service
        log_message "✓ Stopped safe_mode.service"
    fi

    # Step 3: Start measure weight service
    if ! systemctl is-active --quiet measure_weight.service; then
        systemctl start measure_weight.service
        log_message "✓ Started measure_weight.service"
    fi

    # Step 4: Confirm unlock to backend
    CONFIRM_RESPONSE=$(curl -s --max-time 10 \
        -X POST "$API_BASE/devices/$DEVICE_ID/unlock-confirm" \
        -H "Content-Type: application/json" \
        -d "{\"command_id\": $COMMAND_ID}")

    if [ $? -eq 0 ]; then
        log_message "✓ Unlock confirmed to backend"
        log_message "🎉 Device unlocked successfully!"
    else
        log_message "ERROR: Failed to confirm unlock to backend"
    fi
}

# Main execution
check_unlock
