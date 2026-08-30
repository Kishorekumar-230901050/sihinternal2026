# Calibris - Trigger Test Tamper Alert (PowerShell)
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " CALIBRIS - Trigger Test Tamper Alert" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Sending tamper alert to Device 1..." -ForegroundColor Yellow
Write-Host ""

$body = @{
    tamper_type = "PHYSICAL_TAMPER"
    severity = "critical"
    details = "Live demo for jury - Unauthorized access detected"
    city = "Chennai"
    state = "Tamil Nadu"
    latitude = 13.0827
    longitude = 80.2707
    prev_hash = "abc123def456"
    curr_hash = "xyz789ghi012"
    drift = 2.3
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/devices/1/tamper" `
        -Method POST `
        -Body $body `
        -ContentType "application/json" `
        -UseBasicParsing

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " Alert sent successfully!" -ForegroundColor Green
    Write-Host " Check your dashboard for the alert." -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Cyan
    Write-Host $response.Content
}
catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host " ERROR: Failed to send alert" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
