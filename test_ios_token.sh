#!/bin/bash

# ═══════════════════════════════════════════════════════════════════
# Test iOS FCM Token
# ═══════════════════════════════════════════════════════════════════

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

FCM_TOKEN="cbgQHos2jU0auPCpJvXqH4:APA91bGFQRRn9au3A_0dJRtSseojFu5PrBPEj3xGiTrwb4iUXCvk911rssBHA7B9Le_iwOTRu5c5isrx3L26hmsX6UkTFo31kko3LXLfkabV8iZ4mXEKzXM"

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "           🧪 Testing iOS FCM Token 🧪"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo -e "${BLUE}FCM Token:${NC}"
echo "$FCM_TOKEN"
echo ""
echo -e "${BLUE}Token Analysis:${NC}"
echo "  Length: ${#FCM_TOKEN} characters"
echo ""

# Check if token looks valid
if [[ $FCM_TOKEN == *":"* ]]; then
    echo -e "${GREEN}✅ Token format looks valid (contains ':')${NC}"
else
    echo -e "${RED}❌ Token format invalid (should contain ':')${NC}"
fi

if [[ $FCM_TOKEN == *"APA91b"* ]]; then
    echo -e "${GREEN}✅ Token contains FCM signature (APA91b)${NC}"
else
    echo -e "${YELLOW}⚠️  Token doesn't contain FCM signature${NC}"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo -e "${BLUE}🔍 What to do next:${NC}"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "1. Open Firebase Console:"
echo "   https://console.firebase.google.com/project/clinicalsystem-4da35/messaging"
echo ""
echo "2. Click 'New campaign' → 'Firebase Notification messages'"
echo ""
echo "3. Fill in:"
echo "   - Title: اختبار iOS"
echo "   - Text: رسالة تجريبية"
echo ""
echo "4. Click 'Send test message'"
echo ""
echo "5. Paste this FCM Token:"
echo "   $FCM_TOKEN"
echo ""
echo "6. Click '+' then 'Test'"
echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo -e "${YELLOW}📊 Expected Results:${NC}"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo -e "${GREEN}✅ If notification arrives:${NC}"
echo "   → APNs is working!"
echo "   → Problem is in Topic Subscription or Cloud Function"
echo "   → Next: Check Firestore for topic subscriptions"
echo ""
echo -e "${RED}❌ If notification does NOT arrive:${NC}"
echo "   → APNs Key on Firebase is wrong or missing"
echo "   → Next: Upload APNs Key to Firebase Console"
echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo -e "${BLUE}🔑 To check/upload APNs Key:${NC}"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "1. Open Firebase Console:"
echo "   https://console.firebase.google.com/project/clinicalsystem-4da35/settings/cloudmessaging"
echo ""
echo "2. Scroll to 'Apple app configuration'"
echo ""
echo "3. Check if 'APNs Authentication Key' exists"
echo ""
echo "4. If NOT exists or wrong:"
echo "   a. Go to: https://developer.apple.com/account/resources/authkeys/list"
echo "   b. Create new APNs Key"
echo "   c. Download .p8 file"
echo "   d. Upload to Firebase with:"
echo "      - Key ID: [from Apple Developer]"
echo "      - Team ID: YRJ4DLXDZ2"
echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo -e "${GREEN}Ready to test? Go to Firebase Console and send test message! 🚀${NC}"
echo ""
