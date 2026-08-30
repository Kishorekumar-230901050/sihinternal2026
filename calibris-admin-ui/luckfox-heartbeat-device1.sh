#!/bin/bash
# Luckfox Device 1 Heartbeat Script
# Run every 30 seconds via cron to report device is online

API_BASE="https://calibris-fullstack-production.up.railway.app/api"
DEVICE_ID=1

# Send heartbeat to backend
curl -X POST "$API_BASE/devices/$DEVICE_ID/heartbeat" \
  -H "Content-Type: application/json" \
  -d '{"status":"online"}' \
  -s > /dev/null 2>&1

# Log heartbeat (optional - for debugging)
# echo "[$(date '+%Y-%m-%d %H:%M:%S')] Heartbeat sent for Device $DEVICE_ID" >> /home/pico/calibris/data/heartbeat.log
