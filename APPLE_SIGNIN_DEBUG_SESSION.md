# 🔍 Apple & Google Sign-In - Debug Session Guide

## Quick Reference for Testing & Debugging

This guide helps you test the sign-in fixes and debug any remaining issues.

---

## 🧪 Test Scenarios (Copy & Paste Checklist)

### Google Sign-In Test Cases

```
□ Test 1: Normal Sign-In (Happy Path)
  - Open app → Tap Google button → Select account → Should succeed ✅
  - Expected: User logged in, navigates to home screen
  - Log pattern: 🔐 Starting... → Got account → Got tokens → Firebase success

□ Test 2: User Cancellation
  - Open app → Tap Google button → Press back/cancel
  - Expected: Returns to login screen, NO error message, NO crash
  - Log pattern: 🔐 Starting... → User cancelled sign-in

□ Test 3: No Internet Connection
  - Disable WiFi and cellular → Tap Google button
  - Expected: Error SnackBar: "خطأ في الاتصال بالإنترنت، يرجى المحاولة مرة أخرى"
  - Log pattern: 🔐 Starting... → ❌ network error

□ Test 4: Slow Internet (Timeout)
  - Use very slow connection → Tap Google button
  - Expected: After 30s, shows timeout error message
  - Log pattern: 🔐 Starting... → ❌ Timeout

□ Test 5: Rapid Tapping
  - Tap Google button 5 times rapidly
  - Expected: Only one sign-in flow starts, no crash
  - Log pattern: 🔐 Starting... (should appear only once)

□ Test 6: Account Exists with Different Credential
  - Try to sign in with Google using email already used with Apple
  - Expected: Error: "هذا البريد الإلكتروني مسجل بطريقة دخول أخرى"
```

### Apple Sign-In Test Cases

```
□ Test 1: Normal Sign-In (Happy Path)
  - Open app → Tap Apple button → FaceID/Password → Should succeed ✅
  - Expected: User logged in, navigates to home screen
  - Log pattern: 🍎 Starting... → Got credential → Firebase success

□ Test 2: User Cancellation
  - Open app → Tap Apple button → Press cancel
  - Expected: Returns to login screen, NO error message, NO crash
  - Log pattern: 🍎 Starting... → User cancelled

□ Test 3: No Internet Connection
  - Disable WiFi and cellular → Tap Apple button
  - Expected: Error SnackBar: "خطأ في الاتصال بالإنترنت، يرجى المحاولة مرة أخرى"
  - Log pattern: 🍎 Starting... → ❌ network error

□ Test 4: Slow Internet (Timeout)
  - Use very slow connection → Tap Apple button
  - Expected: After 60-90s, shows timeout error message
  - Log pattern: 🍎 Starting... → ❌ Timeout

□ Test 5: Rapid Tapping
  - Tap Apple button 5 times rapidly
  - Expected: Only one sign-in flow starts, no crash
  - Log pattern: 🍎 Starting... (should appear only once)

□ Test 6: Device Rotation During Sign-In
  - Tap Apple button → Rotate device while Apple UI is showing
  - Expected: Sign-in continues normally, no crash
```

---

## 📱 How to View Logs on Physical Device

### Method 1: Xcode Console (Recommended)

1. **Connect iPad to Mac**
   - Use USB cable (better than wireless)

2. **Open Xcode Console**
   ```
   Xcode → Window → Devices and Simulators
   → Select your iPad
   → Click "Open Console" button
   ```

3. **Filter Logs**
   - In search box, type: `Sign-In`
   - This will show only relevant logs with 🔐 and 🍎 prefixes

4. **Run App**
   - Either run from Xcode, or launch already-installed app
   - Console will show all logs in real-time

5. **Test Sign-In**
   - Trigger the sign-in flow
   - Watch logs appear in real-time

### Method 2: View Crash Logs (If App Crashed)

```
Xcode → Window → Devices and Simulators
→ Select your iPad
→ Click "View Device Logs"
→ Find recent crash
→ Export and analyze
```

---

## 🔍 Log Patterns Reference

### Google Sign-In - Success Flow

```
🔐 [Google Sign-In] Starting sign-in flow...
🔐 [Google Sign-In] Got Google account: user@gmail.com
🔐 [Google Sign-In] Got authentication tokens
🔐 [Google Sign-In] Signing in to Firebase...
🔐 [Google Sign-In] Firebase auth successful for abc123xyz
🔐 [Google Sign-In] Creating/Updating user document...
🔐 [AuthCubit] Starting Google Sign-In flow...
🔐 [AuthCubit] Google Sign-In success! Emitting Authenticated state
```
**Expected Result**: User sees home screen

---

### Google Sign-In - User Cancelled

```
🔐 [Google Sign-In] Starting sign-in flow...
🔐 [Google Sign-In] User cancelled sign-in
🔐 [AuthCubit] Starting Google Sign-In flow...
🔐 [AuthCubit] Google Sign-In returned null (user cancelled)
```
**Expected Result**: User returns to login screen, NO error shown

---

### Google Sign-In - Network Error

```
🔐 [Google Sign-In] Starting sign-in flow...
🔐 [Google Sign-In] Got Google account: user@gmail.com
🔐 [Google Sign-In] Got authentication tokens
🔐 [Google Sign-In] Signing in to Firebase...
❌ [Google Sign-In] Firebase auth exception: network-request-failed - ...
❌ [AuthCubit] Google Sign-In error: Exception: خطأ في الاتصال بالإنترنت...
```
**Expected Result**: Red SnackBar with: "خطأ في الاتصال بالإنترنت، يرجى المحاولة مرة أخرى"

---

### Google Sign-In - Timeout

```
🔐 [Google Sign-In] Starting sign-in flow...
🔐 [Google Sign-In] Got Google account: user@gmail.com
🔐 [Google Sign-In] Got authentication tokens
🔐 [Google Sign-In] Signing in to Firebase...
❌ [Google Sign-In] Timeout: Instance of 'TimeoutException'
❌ [AuthCubit] Google Sign-In timeout: TimeoutException: ...
```
**Expected Result**: Red SnackBar with: "انتهت مهلة تسجيل الدخول، يرجى المحاولة مرة أخرى"

---

### Apple Sign-In - Success Flow

```
🍎 [Apple Sign-In] Checking availability...
🍎 [Apple Sign-In] Generating nonce...
🍎 [Apple Sign-In] Requesting Apple ID credential...
🍎 [Apple Sign-In] Got credential, extracting identity token...
🍎 [Apple Sign-In] Creating OAuth credential...
🍎 [Apple Sign-In] Signing in to Firebase...
🍎 [Apple Sign-In] Firebase auth successful for abc123xyz
🍎 [Apple Sign-In] Creating/Updating user document...
🍎 [AuthCubit] Starting Apple Sign-In flow...
🍎 [AuthCubit] Apple Sign-In success! Emitting Authenticated state
```
**Expected Result**: User sees home screen

---

### Apple Sign-In - User Cancelled

```
🍎 [Apple Sign-In] Checking availability...
🍎 [Apple Sign-In] Generating nonce...
🍎 [Apple Sign-In] Requesting Apple ID credential...
🍎 [Apple Sign-In] Authorization exception: AuthorizationErrorCode.canceled
🍎 [Apple Sign-In] User cancelled
🍎 [AuthCubit] Starting Apple Sign-In flow...
🍎 [AuthCubit] Apple Sign-In returned null (user cancelled)
```
**Expected Result**: User returns to login screen, NO error shown

---

### Apple Sign-In - Not Available

```
🍎 [Apple Sign-In] Checking availability...
🍎 [Apple Sign-In] Not available on this device
❌ [Apple Sign-In] Unexpected error: Exception: تسجيل الدخول بواسطة Apple غير متاح...
❌ [AuthCubit] Apple Sign-In error: تسجيل الدخول بواسطة Apple غير متاح على هذا الجهاز
```
**Expected Result**: Red SnackBar with error message
**Note**: This should NEVER happen on real iOS devices with iOS 13+

---

### Apple Sign-In - Network Error

```
🍎 [Apple Sign-In] Checking availability...
🍎 [Apple Sign-In] Generating nonce...
🍎 [Apple Sign-In] Requesting Apple ID credential...
🍎 [Apple Sign-In] Got credential, extracting identity token...
🍎 [Apple Sign-In] Creating OAuth credential...
🍎 [Apple Sign-In] Signing in to Firebase...
❌ [Apple Sign-In] Firebase auth exception: network-request-failed - ...
❌ [AuthCubit] Apple Sign-In error: خطأ في الاتصال بالإنترنت...
```
**Expected Result**: Red SnackBar with: "خطأ في الاتصال بالإنترنت، يرجى المحاولة مرة أخرى"

---

## 🚨 Error Codes Decoder

If you see Firebase error codes in logs, here's what they mean:

| Error Code | Meaning | User Message (Arabic) |
|------------|---------|----------------------|
| `account-exists-with-different-credential` | Email already used with different provider | "هذا البريد الإلكتروني مسجل بطريقة دخول أخرى" |
| `invalid-credential` | Bad credential data | "بيانات الاعتماد غير صالحة، يرجى المحاولة مرة أخرى" |
| `operation-not-allowed` | Provider disabled in Firebase | "تسجيل الدخول بواسطة Google/Apple غير مفعّل حالياً" |
| `user-disabled` | Account disabled by admin | "تم تعطيل هذا الحساب" |
| `user-not-found` | User doesn't exist | "لم يتم العثور على هذا المستخدم" |
| `network-request-failed` | Internet connection issue | "خطأ في الاتصال بالإنترنت، يرجى المحاولة مرة أخرى" |

---

## 🐛 Common Issues & Solutions

### Issue 1: Google Sign-In Shows "Client ID not found"

**Symptoms:**
- Error message about missing client ID
- Logs show: `Missing GIDClientID`

**Solution:**
```bash
# Verify Info.plist has correct value
cat ios/Runner/Info.plist | grep -A 1 "GIDClientID"

# Should show:
# <key>GIDClientID</key>
# <string>718616577077-1q7n6ub417t7naj1ufo1cb1ji3i88g5d.apps.googleusercontent.com</string>
```

If missing, add it manually to `ios/Runner/Info.plist`

---

### Issue 2: Apple Sign-In Shows "Invalid Response"

**Symptoms:**
- Error: "استجابة غير صالحة من Apple"
- Logs show: `AuthorizationErrorCode.invalidResponse`

**Possible Causes:**
1. Bundle ID mismatch in Apple Developer Console
2. Service ID not configured correctly
3. Redirect URI not matching

**Solution:**
1. Verify Bundle ID: `com.mored.mallawycare`
2. Check Apple Developer Console → Identifiers → App ID
3. Check Service ID configuration
4. Verify redirect URI: `https://clinicalsystem-4da35.firebaseapp.com/__/auth/handler`

---

### Issue 3: Sign-In Works in Debug but Fails in Release

**Symptoms:**
- Works fine when running from Xcode
- Fails in TestFlight or App Store build

**Possible Causes:**
1. Provisioning profile mismatch
2. Entitlements not included in release build
3. Different bundle ID in release

**Solution:**
```bash
# Check release build configuration
cd ios
cat Runner/Release.xcconfig

# Verify entitlements are copied
ls -la Runner/*.entitlements

# Build release and check for errors
flutter build ios --release
```

---

### Issue 4: "Identity Token is Missing"

**Symptoms:**
- Apple Sign-In fails with: "فشل الحصول على بيانات التفويض من Apple"
- Logs show: `Identity token is null or empty`

**Possible Causes:**
1. Apple Sign-In not enabled in Apple Developer Console
2. Bundle ID not added to Service ID
3. Nonce generation issue

**Solution:**
1. Check Apple Developer Console → Certificates, IDs & Profiles
2. Go to Identifiers → Your App ID
3. Verify "Sign In with Apple" capability is enabled
4. Go to your Service ID
5. Verify domain and redirect URL are configured

---

## 🎯 Before Submitting to App Store

### Final Checklist

```
□ All tests passed on physical iPad
□ No crashes in any scenario
□ All error messages are in Arabic
□ User can always "skip" and use app as guest
□ Tested with WiFi only
□ Tested with cellular only
□ Tested with no internet
□ Tested with VPN enabled
□ Tested cancellation flows
□ Checked logs - no unexpected errors
□ Built release version successfully
□ Uploaded to TestFlight
□ Tested TestFlight build (not just debug build!)
```

---

## 📊 Success Metrics

Your app is ready when:

✅ **No Crashes**: App never crashes, regardless of user action  
✅ **Clear Errors**: All errors show user-friendly Arabic messages  
✅ **Graceful Failures**: Network/timeout errors handled smoothly  
✅ **User Control**: User can cancel without seeing errors  
✅ **Fallback Available**: "Skip and continue as guest" always works  

---

## 📞 Quick Reference Commands

```bash
# View logs in terminal (if running from Xcode)
# Just run the app and logs will appear in Xcode console

# Clean build
flutter clean && flutter pub get

# Reinstall pods
cd ios && pod install && cd ..

# Build release
flutter build ios --release

# Check git status
git status

# See recent commits
git log --oneline -5

# View a specific file
cat lib/features/auth/data/repositories/auth_repository.dart
```

---

**Created**: June 12, 2026  
**Purpose**: Debug & test sign-in fixes for App Store review  
**Status**: Ready for testing  

**Next Step**: Test all scenarios on physical iPad, then submit to App Store
