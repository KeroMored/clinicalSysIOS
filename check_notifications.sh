#!/bin/bash

# Script to check Firebase Push Notifications setup
# Run: bash check_notifications.sh

echo "🔍 Checking Firebase Push Notifications Setup..."
echo "================================================"
echo ""

# Check 1: Firebase CLI
echo "1️⃣ Checking Firebase CLI..."
if command -v firebase &> /dev/null; then
    echo "✅ Firebase CLI installed: $(firebase --version)"
else
    echo "❌ Firebase CLI NOT installed!"
    echo "   Install: npm install -g firebase-tools"
    exit 1
fi
echo ""

# Check 2: Firebase Login
echo "2️⃣ Checking Firebase Login..."
firebase projects:list &> /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Logged in to Firebase"
else
    echo "❌ NOT logged in to Firebase!"
    echo "   Run: firebase login"
    exit 1
fi
echo ""

# Check 3: Current Project
echo "3️⃣ Checking Firebase Project..."
cd "$(dirname "$0")"
PROJECT=$(firebase use 2>&1 | grep "Active Project" | awk '{print $NF}')
if [ -z "$PROJECT" ]; then
    echo "⚠️  No active project set"
    echo "   Setting project..."
    firebase use clinicalsystem-4da35
    PROJECT="clinicalsystem-4da35"
fi
echo "✅ Active Project: $PROJECT"
echo ""

# Check 4: Functions Deployed
echo "4️⃣ Checking Deployed Cloud Functions..."
FUNCTIONS=$(firebase functions:list 2>&1)
if echo "$FUNCTIONS" | grep -q "notifyClinicOnNewBooking"; then
    echo "✅ notifyClinicOnNewBooking - DEPLOYED"
else
    echo "❌ notifyClinicOnNewBooking - NOT DEPLOYED"
fi

if echo "$FUNCTIONS" | grep -q "notifyUsersOnNewOffer"; then
    echo "✅ notifyUsersOnNewOffer - DEPLOYED"
else
    echo "❌ notifyUsersOnNewOffer - NOT DEPLOYED"
fi

if echo "$FUNCTIONS" | grep -q "notifyPharmaciesOnNewRequest"; then
    echo "✅ notifyPharmaciesOnNewRequest - DEPLOYED"
else
    echo "❌ notifyPharmaciesOnNewRequest - NOT DEPLOYED"
fi

if echo "$FUNCTIONS" | grep -q "notifyLabOnNewBooking"; then
    echo "✅ notifyLabOnNewBooking - DEPLOYED"
else
    echo "❌ notifyLabOnNewBooking - NOT DEPLOYED"
fi
echo ""

# Check 5: Functions Status
echo "5️⃣ Checking if any functions are NOT deployed..."
if echo "$FUNCTIONS" | grep -q "No functions deployed"; then
    echo "❌ NO FUNCTIONS DEPLOYED!"
    echo ""
    echo "🔧 SOLUTION: Deploy functions now"
    echo "   Run: firebase deploy --only functions"
    echo ""
    read -p "Deploy functions now? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🚀 Deploying functions..."
        firebase deploy --only functions
    fi
else
    echo "✅ Functions are deployed"
fi
echo ""

# Check 6: Recent Function Logs
echo "6️⃣ Checking Recent Function Logs..."
echo "   (Last 5 log entries)"
firebase functions:log --limit 5 2>&1 | head -20
echo ""

# Summary
echo "================================================"
echo "📋 SUMMARY"
echo 
echo ""
echo "Next Steps:"
echo "1. If functions NOT deployed → Run: firebase deploy --only functions"
echo "2. Test booking: Make online clinic booking → Check if notification arrives"
echo "3. Test offer: Create pharmacy offer → Check if notification arrives"
echo "4. Check Xcode Console for FCM Token: Should see '📱 FCM Token: ...'"
echo "5. Check Firebase C"================================================"onsole → Firestore:"
echo "   - clinic_subscriptions → fcmToken should exist"
echo "   - users → fcmToken should exist"
echo ""
echo "🔍 For detailed debugging, see: CHECK_NOTIFICATIONS_DEBUG.md"
echo ""
