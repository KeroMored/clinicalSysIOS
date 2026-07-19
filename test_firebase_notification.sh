#!/bin/bash

# ═══════════════════════════════════════════════════════════════════
# Test Firebase Notification Script for iOS
# ═══════════════════════════════════════════════════════════════════
# 
# Usage:
# 1. Get FCM Token from Xcode Console when running the app
# 2. Run: ./test_firebase_notification.sh YOUR_FCM_TOKEN_HERE
# 
# This script sends a test notification to a specific device token
# ═══════════════════════════════════════════════════════════════════

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "           🔔 Firebase iOS Notification Test Tool 🔔"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Check if FCM token provided
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: FCM Token required!${NC}"
    echo ""
    echo "Usage:"
    echo "  ./test_firebase_notification.sh YOUR_FCM_TOKEN"
    echo ""
    echo "To get your FCM Token:"
    echo "  1. Open project in Xcode: open ios/Runner.xcworkspace"
    echo "  2. Run app on real device (not Simulator)"
    echo "  3. Look in Console for: 📱 FCM Token: xxx"
    echo "  4. Copy the token and run this script"
    echo ""
    exit 1
fi

FCM_TOKEN="$1"
PROJECT_ID="clinicalsystem-4da35"

echo -e "${BLUE}📋 Configuration:${NC}"
echo "   Project ID: $PROJECT_ID"
echo "   FCM Token: ${FCM_TOKEN:0:20}...${FCM_TOKEN: -20}"
echo ""

# Test 1: Send to specific device token
echo -e "${YELLOW}📤 Test 1: Sending notification to device token...${NC}"

RESPONSE=$(curl -s -X POST "https://fcm.googleapis.com/fcm/send" \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "'$FCM_TOKEN'",
    "notification": {
      "title": "اختبار iOS 🍎",
      "body": "إشعار تجريبي مباشر للجهاز"
    },
    "data": {
      "type": "test",
      "timestamp": "'$(date +%s)'"
    },
    "priority": "high",
    "apns": {
      "payload": {
        "aps": {
          "sound": "default",
          "badge": 1,
          "alert": {
            "title": "اختبار iOS 🍎",
            "body": "إشعار تجريبي مباشر للجهاز"
          }
        }
      }
    }
  }')

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Request sent successfully!${NC}"
    echo "   Response: $RESPONSE"
else
    echo -e "${RED}❌ Request failed!${NC}"
    echo "   Response: $RESPONSE"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo -e "${BLUE}🔍 What to check now:${NC}"
echo ""
echo "1. ✅ Did you receive a notification on your iOS device?"
echo "   - If YES: APNs is working! Problem is in topic subscription"
echo "   - If NO: Continue to troubleshooting below"
echo ""
echo "2. Check Xcode Console for:"
echo "   - '📩 Got a message whilst in the foreground!'"
echo "   - '📊 Message data: ...'"
echo ""
echo "3. If nothing appears:"
echo "   - FCM Token might be invalid or expired"
echo "   - APNs Key not configured correctly in Firebase"
echo "   - Device not connected to internet"
echo "   - Notification permissions denied"
echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo -e "${YELLOW}⚠️  Note: This script uses legacy FCM API${NC}"
echo -e "${YELLOW}    For production, use Firebase Admin SDK or Cloud Functions${NC}"
echo ""
echo -e "${BLUE}📚 Next steps:${NC}"
echo "   1. If test worked: Check topic subscriptions in Firestore"
echo "   2. If test failed: Check APNs key in Firebase Console"
echo "   3. See XCODE_NOTIFICATION_DEBUG_GUIDE.md for full guide"
echo ""
