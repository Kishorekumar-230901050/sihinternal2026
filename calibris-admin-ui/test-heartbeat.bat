@echo off
echo ========================================
echo  CALIBRIS - Test Heartbeat Endpoint
echo ========================================
echo.
echo Testing Device 1 heartbeat...
echo.

curl -X POST http://localhost:3000/api/devices/1/heartbeat ^
  -H "Content-Type: application/json" ^
  -d "{\"status\":\"online\"}"

echo.
echo.
echo Testing Device 2 heartbeat...
echo.

curl -X POST http://localhost:3000/api/devices/2/heartbeat ^
  -H "Content-Type: application/json" ^
  -d "{\"status\":\"online\"}"

echo.
echo.
echo ========================================
echo Heartbeat test complete!
echo Check your database to verify last_seen was updated.
echo ========================================
pause
