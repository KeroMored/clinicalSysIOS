#!/bin/bash

# ═══════════════════════════════════════════════════════════════════
# iOS Push Notifications Configuration Checker
# ═══════════════════════════════════════════════════════════════════

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "       🔍 iOS Push Notifications Configuration Checker 🔍"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

PROJECT_DIR="/Users/georgesadek/Downloads/clinicalSys-main"
cd "$PROJECT_DIR"

# Check 1: Runner.entitlements
echo -e "${BLUE}📋 Check 1: Runner.entitlements${NC}"
if [ -f "ios/Runner/Runner.entitlements" ]; then
    if grep -q "aps-environment" ios/Runner/Runner.entitlements; then
        APS_ENV=$(grep -A1 "aps-environment" ios/Runner/Runner.entitlements | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
        echo -e "${GREEN}✅ aps-environment found: $APS_ENV${NC}"
    else
        echo -e "${RED}❌ aps-environment NOT found in entitlements!${NC}"
    fi
else
    echo -e "${RED}❌ Runner.entitlements file NOT found!${NC}"
fi
echo ""

# Check 2: GoogleService-Info.plist
echo -e "${BLUE}📋 Check 2: GoogleService-Info.plist${NC}"
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    BUNDLE_ID=$(grep -A1 "BUNDLE_ID" ios/Runner/GoogleService-Info.plist | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    APP_ID=$(grep -A1 "GOOGLE_APP_ID" ios/Runner/GoogleService-Info.plist | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    echo -e "${GREEN}✅ GoogleService-Info.plist found${NC}"
    echo "   Bundle ID: $BUNDLE_ID"
    echo "   App ID: $APP_ID"
    
    if [ "$BUNDLE_ID" = "com.mored.mallawicure" ]; then
        echo -e "${GREEN}   ✅ Bundle ID correct${NC}"
    else
        echo -e "${RED}   ❌ Bundle ID incorrect! Should be: com.mored.mallawicure${NC}"
    fi
    
    if [ "$APP_ID" = "1:718616577077:ios:6593a7fcafb54348189d7c" ]; then
        echo -e "${GREEN}   ✅ App ID correct${NC}"
    else
        echo -e "${RED}   ❌ App ID incorrect! Should be: 1:718616577077:ios:6593a7fcafb54348189d7c${NC}"
    fi
else
    echo -e "${RED}❌ GoogleService-Info.plist NOT found!${NC}"
fi
echo ""

# Check 3: firebase_options.dart
echo -e "${BLUE}📋 Check 3: firebase_options.dart${NC}"
if [ -f "lib/firebase_options.dart" ]; then
    if grep -q "iosBundleId: 'com.mored.mallawicure'" lib/firebase_options.dart; then
        echo -e "${GREEN}✅ iosBundleId correct in firebase_options.dart${NC}"
    else
        echo -e "${RED}❌ iosBundleId incorrect in firebase_options.dart${NC}"
    fi
    
    if grep -q "1:718616577077:ios:6593a7fcafb54348189d7c" lib/firebase_options.dart; then
        echo -e "${GREEN}✅ iOS App ID correct in firebase_options.dart${NC}"
    else
        echo -e "${RED}❌ iOS App ID incorrect in firebase_options.dart${NC}"
    fi
else
    echo -e "${RED}❌ firebase_options.dart NOT found!${NC}"
fi
echo ""

# Check 4: Info.plist permissions
echo -e "${BLUE}📋 Check 4: Info.plist notification permissions${NC}"
if [ -f "ios/Runner/Info.plist" ]; then
    echo -e "${GREEN}✅ Info.plist found${NC}"
    # Note: Notification permissions are requested at runtime, not in Info.plist
else
    echo -e "${RED}❌ Info.plist NOT found!${NC}"
fi
echo ""

# Check 5: Podfile
echo -e "${BLUE}📋 Check 5: Podfile${NC}"
if [ -f "ios/Podfile" ]; then
    if grep -q "platform :ios" ios/Podfile; then
        IOS_VERSION=$(grep "platform :ios" ios/Podfile | sed "s/.*platform :ios, '\(.*\)'.*/\1/")
        echo -e "${GREEN}✅ Podfile found (iOS $IOS_VERSION)${NC}"
        
        if (( $(echo "$IOS_VERSION >= 12.0" | bc -l) )); then
            echo -e "${GREEN}   ✅ iOS version OK for Push Notifications${NC}"
        else
            echo -e "${RED}   ❌ iOS version too old (needs >= 12.0)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Could not determine iOS version from Podfile${NC}"
    fi
else
    echo -e "${RED}❌ Podfile NOT found!${NC}"
fi
echo ""

# Check 6: Check for common issues
echo -e "${BLUE}📋 Check 6: Common Issues${NC}"

# Check if firebase_messaging is in pubspec.yaml
if grep -q "firebase_messaging:" pubspec.yaml; then
    echo -e "${GREEN}✅ firebase_messaging dependency found${NC}"
else
    echo -e "${RED}❌ firebase_messaging dependency NOT found!${NC}"
fi

# Check if flutter_local_notifications is in pubspec.yaml
if grep -q "flutter_local_notifications:" pubspec.yaml; then
    echo -e "${GREEN}✅ flutter_local_notifications dependency found${NC}"
else
    echo -e "${YELLOW}⚠️  flutter_local_notifications dependency NOT found${NC}"
fi

echo ""

# Summary
echo "═══════════════════════════════════════════════════════════════════"
echo -e "${BLUE}📊 Summary${NC}"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "Configuration files checked. Now you need to:"
echo ""
echo "1. Open Xcode:"
echo "   open ios/Runner.xcworkspace"
echo ""
echo "2. Check 'Signing & Capabilities':"
echo "   - Runner target → Signing & Capabilities tab"
echo "   - Verify 'Push Notifications' capability is added"
echo "   - Verify Team is: YRJ4DLXDZ2 (Organization)"
echo "   - Verify Bundle ID is: com.mored.mallawicure"
echo ""
echo "3. Run app on REAL device (not Simulator)"
echo ""
echo "4. Check Xcode Console for:"
echo "   📱 FCM Token: xxx"
echo ""
echo "5. If FCM Token is null:"
echo "   - Check internet connection"
echo "   - Check notification permissions"
echo "   - Check APNs key on Firebase Console"
echo ""
echo "6. If FCM Token exists but notifications don't arrive:"
echo "   - Check APNs key on Firebase Console"
echo "   - Key ID should match Apple Developer key"
echo "   - Team ID should be: YRJ4DLXDZ2"
echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo ""
