# 🍎 Apple Sign-In Error 1000 Fix

## 🔴 The Problem
```
AuthorizationErrorCode.unknown (error 1000)
= Team ID mismatch or invalid provisioning profile
```

Your Team ID is: **84M47YB8XR**

---

## ✅ What I Fixed

### 1. Updated Runner.entitlements ✓
Added:
- `keychain-access-groups` with Team ID prefix
- `associated-domains` for proper app linking

### 2. Updated Podfile ✓
Added:
- Team ID to all pod targets
- Code signing style set to Automatic
- Proper development team propagation

---

## 🚀 Next Steps (CRITICAL)

### Step 1: Delete Old Pods
```bash
cd /Users/georgesadek/Downloads/clinicalSys-main
rm -rf ios/Pods ios/Podfile.lock
```

### Step 2: Reinstall Pods with New Settings
```bash
cd ios
pod install --repo-update
cd ..
```

### Step 3: Clean Flutter
```bash
flutter clean
rm -rf build/
```

### Step 4: Fresh Dependencies
```bash
flutter pub get
```

### Step 5: Run on Device
```bash
flutter run -d ios -v
```

---

## 🔍 If Still Getting Error 1000

### Check Provisioning Profile:

1. Open Xcode:
```bash
open ios/Runner.xcworkspace
```

2. Select `Runner` target → `Signing & Capabilities`

3. Verify:
   - ✅ Team is set to your account
   - ✅ Automatically manage signing is ON
   - ✅ Bundle ID = `com.mallawy.clinicalsystem`
   - ✅ Sign in with Apple capability exists

4. If not, delete and recreate:
   - Click `-` to remove current profile
   - Select `+ Capability` → `Sign in with Apple`
   - Xcode will recreate profile automatically

5. **IMPORTANT**: Run on physical device (not simulator)
   - Device must have iCloud account logged in
   - Simulator may not support Apple Sign-In properly

---

## 📱 Test on Device

```bash
# List devices
flutter devices

# Run on real iOS device
flutter run -d <device_name> -v
```

Watch console for these logs:
```
🍎 [Apple Sign-In] Checking availability...
🍎 [Apple Sign-In] Generating nonce...
🍎 [Apple Sign-In] Requesting Apple ID credential...
```

If you see these, great! Error 1000 is fixed. If not, share next error message.

---

## 📋 Alternative: Regenerate Provisioning Profile

If issue persists, do this in Apple Developer Portal:

1. Go to https://developer.apple.com/account/resources/certificates/list
2. Find your development certificate
3. Delete the old provisioning profile for `com.mallawy.clinicalsystem`
4. Create a new one:
   - App ID: `com.mallawy.clinicalsystem`
   - Devices: Select your test device
   - Certificate: Select your dev certificate
   - Capabilities: Enable "Sign In with Apple"
5. Download & install in Xcode

---

## 🆘 Quick Checklist

- [ ] Deleted ios/Pods and ios/Podfile.lock
- [ ] Ran `pod install --repo-update`
- [ ] Ran `flutter clean`
- [ ] Ran `flutter pub get`
- [ ] Opened `ios/Runner.xcworkspace` (not .xcodeproj)
- [ ] Verified Team ID in Signing & Capabilities
- [ ] Verified Apple Sign-In capability exists
- [ ] Device is logged into iCloud
- [ ] Running on physical device (not simulator)

---

**Run this command chain now:**

```bash
cd /Users/georgesadek/Downloads/clinicalSys-main && \
rm -rf ios/Pods ios/Podfile.lock && \
cd ios && pod install --repo-update && cd .. && \
flutter clean && \
flutter pub get && \
flutter run -d ios -v
```

Then share the console output! 🚀
