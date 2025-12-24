#!/bin/bash

# Test notification script
# Usage: ./test_booking_notification.sh <clinicId>

CLINIC_ID=$1

if [ -z "$CLINIC_ID" ]; then
  echo "Usage: ./test_booking_notification.sh <clinicId>"
  exit 1
fi

echo "Creating test booking for clinic: $CLINIC_ID"

# Use Firebase CLI to create a test booking
firebase firestore:set bookings/test_booking_$(date +%s) \
  "patientName=مريض تجريبي" \
  "patientPhone=01234567890" \
  "clinicId=$CLINIC_ID" \
  "doctorName=د. أحمد" \
  "bookingNumber=99" \
  "status=pending" \
  "createdAt=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  "notes=حجز تجريبي"

echo "Test booking created! Check your device for notification."
