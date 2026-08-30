@echo off
echo ========================================
echo  CALIBRIS - Trigger Test Tamper Alert
echo ========================================
echo.
echo Sending tamper alert to Device 1...
echo.

curl -X POST http://localhost:3000/api/devices/1/tamper ^
  -H "Content-Type: application/json" ^
  -d "{\"tamper_type\":\"PHYSICAL_TAMPER\",\"severity\":\"critical\",\"details\":\"Live demo for jury - Unauthorized access detected\",\"city\":\"Chennai\",\"state\":\"Tamil Nadu\",\"latitude\":13.0827,\"longitude\":80.2707,\"prev_hash\":\"abc123def456\",\"curr_hash\":\"xyz789ghi012\",\"drift\":2.3}"

echo.
echo.
echo ========================================
echo Alert sent! Check your dashboard.
echo ========================================
pause
