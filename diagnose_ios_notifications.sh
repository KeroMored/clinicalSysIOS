#!/bin/bash

echo "🔍 iOS Push Notifications Diagnostic Tool"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check 1: GoogleService-Info.plist
echo "1️⃣ Checking GoogleService-Info.plist..."
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    BUNDLE_ID=$(grep -A1 "BUNDLE_ID" ios/Runner/GoogleService-Info.plist | grep string | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    APP_ID=$(grep -A1 "GOOGLE_APP_ID" ios/Runner/GoogleService-Info.plist | grep string | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    
    echo "   Bundle ID: $BUNDLE_ID"
    echo "   App ID: $APP_ID"
    
    if [ "$BUNDLE_ID" = "com.mored.mallawicure" ]; then
        echo -e "   ${GREEN}✅ Bundle ID correct${NC}"
    else
        echo -e "   ${RED}❌ Bundle ID wrong! Should be: com.mored.mallawicure${NC}"
    fi
    
    if [ "$APP_ID" = "1:718616577077:ios:6593a7fcafb54348189d7c" ]; then
        echo -e "   ${GREEN}✅ App ID correct${NC}"
    else
        echo -e "   ${RED}❌ App ID wrong! Should be: 1:718616577077:ios:6593a7fcafb54348189d7c${NC}"
    fi
else
    echo -e "   ${RED}❌ GoogleService-Info.plist not found!${NC}"
fi

echo ""

# Check 2: firebase_options.dart
echo "2️⃣ Checking firebase_options.dart..."
IOS_APP_ID=$(grep "appId:" lib/firebase_options.dart | grep "ios:" | head -1 | sed "s/.*'\(.*\)'.*/\1/")
IOS_BUNDLE=$(grep "iosBundleId:" lib/firebase_options.dart | head -1 | sed "s/.*'\(.*\)'.*/\1/")

echo "   iOS App ID: $IOS_APP_ID"
echo "   iOS Bundle ID: $IOS_BUNDLE"

if [ "$IOS_APP_ID" = "1:718616577077:ios:6593a7fcafb54348189d7c" ]; then
    echo -e "   ${GREEN}✅ iOS App ID correct${NC}"
else
    echo -e "   ${RED}❌ iOS App ID wrong!${NC}"
fi

if [ "$IOS_BUNDLE" = "com.mored.mallawicure" ]; then
    echo -e "   ${GREEN}✅ iOS Bundle ID correct${NC}"
else
    echo -e "   ${RED}❌ iOS Bundle ID wrong!${NC}"
fi

echo ""

# Check 3: Info.plist
echo "3️⃣ Checking Info.plist..."
if [ -f "ios/Runner/Info.plist" ]; then
    if grep -q "UIBackgroundModes" ios/Runner/Info.plist; then
        if grep -q "remote-notification" ios/Runner/Info.plist; then
            echo -e "   ${GREEN}✅ Background modes enabled${NC}"
        else
            echo -e "   ${RED}❌ remote-notification not enabled${NC}"
        fi
    else
        echo -e "   ${YELLOW}⚠️  UIBackgroundModes not found${NC}"
    fi
else
    echo -e "   ${RED}❌ Info.plist not found${NC}"
fi

echo ""

# Check 4: Cloud Functions
echo "4️⃣ Checking Cloud Functions deployment..."
echo -e "   ${YELLOW}⏳ Please check manually:${NC}"
echo "   https://console.firebase.google.com/project/clinicalsystem-4da35/functions"
echo ""
echo "   Required functions:"
echo "   - notifyClinicOnNewBooking"
echo "   - notifyUsersOnNewOffer"
echo "   - notifyPharmaciesOnNewRequest"
echo "   - notifyLabOnNewBooking"

echo ""

# Check 5: APNs Key
echo "5️⃣ Checking APNs Configuration..."
echo -e "   ${YELLOW}⏳ Please check manually:${NC}"
echo "   https://console.firebase.google.com/project/clinicalsystem-4da35/settings/cloudmessaging/ios:6593a7fcafb54348189d7c"
echo ""
echo "   Required:"
echo "   - APNs Authentication Key uploaded"
echo "   - Key ID: 9QY3DKL5BG"
echo "   - Team ID: YRJ4DLXDZ2"

echo ""
echo "=========================================="
echo "🎯 Next Steps:"
echo "=========================================="
echo ""
echo "1. If any ❌ above, fix them first"
echo "2. If all ✅, the issue is likely APNs Key"
echo "3. Run this on iOS device after login:"
echo "   - Open app"
echo "   - Check Xcode console for: 📱 FCM Token: xxx"
echo "   - If Token is null → APNs issue"
echo "   - If Token exists → Check topic subscription"
echo ""
echo "4. Test notification:"
echo "   https://console.firebase.google.com/project/clinicalsystem-4da35/notification/compose"
echo "   - Send to Topic: all_users"
echo ""
