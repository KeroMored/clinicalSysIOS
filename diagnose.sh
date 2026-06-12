#!/bin/bash

# Diagnostic script for Mallawy Care Sign-In issues
# Run this to check your current setup

echo "🔍 Mallawy Care - Sign-In Diagnostic Tool"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Run this script from the project root directory"
    exit 1
fi

echo "✅ Project directory: OK"
echo ""

# Check Flutter
echo "📱 Checking Flutter..."
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    echo "✅ Flutter: $FLUTTER_VERSION"
else
    echo "❌ Flutter not found"
fi
echo ""

# Check iOS setup
echo "🍎 Checking iOS setup..."
if [ -d "ios" ]; then
    echo "✅ iOS directory exists"
    
    # Check Pods
    if [ -d "ios/Pods" ]; then
        echo "✅ CocoaPods installed"
    else
        echo "⚠️  CocoaPods not installed - run 'cd ios && pod install'"
    fi
    
    # Check GoogleService-Info.plist
    if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
        echo "✅ GoogleService-Info.plist exists"
        
        # Extract Bundle ID
        BUNDLE_ID=$(grep -A 1 "BUNDLE_ID" ios/Runner/GoogleService-Info.plist | grep "string" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
        echo "   Bundle ID: $BUNDLE_ID"
        
        if [ "$BUNDLE_ID" = "com.mored.mallawycare" ]; then
            echo "   ✅ Bundle ID is correct"
        else
            echo "   ❌ Bundle ID should be: com.mored.mallawycare"
        fi
        
        # Extract Client ID
        CLIENT_ID=$(grep -A 1 "CLIENT_ID" ios/Runner/GoogleService-Info.plist | grep "string" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
        echo "   Client ID: $CLIENT_ID"
        
        if [ "$CLIENT_ID" = "718616577077-1q7n6ub417t7naj1ufo1cb1ji3i88g5d.apps.googleusercontent.com" ]; then
            echo "   ✅ Client ID is correct"
        else
            echo "   ❌ Client ID mismatch"
        fi
    else
        echo "❌ GoogleService-Info.plist not found"
    fi
    
    # Check Info.plist
    if [ -f "ios/Runner/Info.plist" ]; then
        echo "✅ Info.plist exists"
        
        # Check GIDClientID
        if grep -q "GIDClientID" ios/Runner/Info.plist; then
            GID_CLIENT_ID=$(grep -A 1 "GIDClientID" ios/Runner/Info.plist | grep "string" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
            echo "   GIDClientID: $GID_CLIENT_ID"
            
            if [ "$GID_CLIENT_ID" = "718616577077-1q7n6ub417t7naj1ufo1cb1ji3i88g5d.apps.googleusercontent.com" ]; then
                echo "   ✅ GIDClientID matches GoogleService-Info.plist"
            else
                echo "   ❌ GIDClientID mismatch"
            fi
        else
            echo "   ❌ GIDClientID not found in Info.plist"
        fi
        
        # Check URL Schemes
        if grep -q "com.googleusercontent.apps.718616577077-1q7n6ub417t7naj1ufo1cb1ji3i88g5d" ios/Runner/Info.plist; then
            echo "   ✅ URL Scheme configured correctly"
        else
            echo "   ❌ URL Scheme not found or incorrect"
        fi
    else
        echo "❌ Info.plist not found"
    fi
else
    echo "❌ iOS directory not found"
fi
echo ""

# Check pubspec.yaml
echo "📦 Checking dependencies..."
if [ -f "pubspec.yaml" ]; then
    if grep -q "google_sign_in:" pubspec.yaml; then
        echo "✅ google_sign_in dependency found"
    else
        echo "❌ google_sign_in dependency not found"
    fi
    
    if grep -q "sign_in_with_apple:" pubspec.yaml; then
        echo "✅ sign_in_with_apple dependency found"
    else
        echo "❌ sign_in_with_apple dependency not found"
    fi
    
    if grep -q "firebase_auth:" pubspec.yaml; then
        echo "✅ firebase_auth dependency found"
    else
        echo "❌ firebase_auth dependency not found"
    fi
fi
echo ""

# Check for cached files that might cause issues
echo "🧹 Checking for problematic cache files..."
ISSUES_FOUND=0

if [ -d "build" ]; then
    echo "⚠️  build/ directory exists (should be cleaned)"
    ISSUES_FOUND=1
fi

if [ -f "ios/Podfile.lock" ] && [ -d "ios/Pods" ]; then
    # Check if Pods are outdated
    echo "ℹ️  CocoaPods cache exists (consider cleaning if issues persist)"
fi

if [ -d "ios/.symlinks" ]; then
    echo "⚠️  .symlinks directory exists (should be cleaned)"
    ISSUES_FOUND=1
fi

if [ $ISSUES_FOUND -eq 1 ]; then
    echo ""
    echo "🔧 Recommended: Run cleanup script"
    echo "   flutter clean && rm -rf ios/Pods ios/.symlinks ios/Podfile.lock"
else
    echo "✅ No problematic cache files found"
fi
echo ""

# Summary
echo "📋 SUMMARY"
echo "=========================================="
echo "Next steps:"
echo "1. If any ❌ found above, fix those issues first"
echo "2. Read CHECK_FIREBASE.md to verify Firebase Console settings"
echo "3. Run: flutter clean && cd ios && pod install && cd .."
echo "4. Delete app from device completely"
echo "5. Restart your device"
echo "6. Run: flutter run --release"
echo ""
echo "For detailed instructions, see: COMPLETE_FIX_NOW.md"
