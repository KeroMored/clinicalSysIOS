# Test Booking Notification - PowerShell Script
# Usage: .\test_booking_notification.ps1 -ClinicId "your_clinic_id"

param(
    [Parameter(Mandatory=$true)]
    [string]$ClinicId
)

Write-Host "Creating test booking for clinic: $ClinicId" -ForegroundColor Green

# Create test booking data
$timestamp = [int][double]::Parse((Get-Date -UFormat %s))
$bookingId = "test_booking_$timestamp"

Write-Host "Booking ID: $bookingId" -ForegroundColor Yellow

# Use Firebase CLI to create a test booking
firebase firestore:set "bookings/$bookingId" `
  --data "{`
    `"patientName`": `"مريض تجريبي`",`
    `"patientPhone`": `"01234567890`",`
    `"clinicId`": `"$ClinicId`",`
    `"doctorName`": `"د. أحمد`",`
    `"bookingNumber`": 99,`
    `"status`": `"pending`",`
    `"createdAt`": {`"_seconds`": $timestamp, `"_nanoseconds`": 0},`
    `"notes`": `"حجز تجريبي للاختبار`"`
  }"

Write-Host "`n✅ Test booking created successfully!" -ForegroundColor Green
Write-Host "📱 Check your device for notification..." -ForegroundColor Cyan
Write-Host "`nBooking Details:" -ForegroundColor Yellow
Write-Host "  - Clinic ID: $ClinicId"
Write-Host "  - Booking ID: $bookingId"
Write-Host "  - Patient: مريض تجريبي"
Write-Host "  - Booking #: 99"
