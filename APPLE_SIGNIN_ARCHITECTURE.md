# 🍎 Apple Sign-In Architecture & Flow

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    iOS Device/Simulator                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Flutter App (LoginScreen)                     │   │
│  │  - Apple Sign-In Button                              │   │
│  │  - AuthCubit → signInWithApple()                      │   │
│  └──────────────┬───────────────────────────────────────┘   │
│                 │                                             │
│                 ▼                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │    AuthRepository.signInWithApple()                   │   │
│  │  1. Check availability                                │   │
│  │  2. Generate nonce                                   │   │
│  │  3. Request Apple ID credential                     │   │
│  │  4. Get identity token                              │   │
│  │  5. Create OAuth credential                         │   │
│  │  6. Sign in to Firebase                             │   │
│  │  7. Upsert user document                            │   │
│  └──────────────┬───────────────────────────────────────┘   │
│                 │                                             │
│  ┌──────────────▼───────────────────────────────────────┐   │
│  │         System Frameworks (iOS)                       │   │
│  │  - SignInWithApple.getAppleIDCredential()             │   │
│  │  - Shows Apple Sign-In Sheet                         │   │
│  │  - User enters credentials                           │   │
│  └──────────────┬───────────────────────────────────────┘   │
│                 │                                             │
└─────────────────┼─────────────────────────────────────────────┘
                  │
     ┌────────────▼────────────┐
     │   Apple ID Servers      │
     │   (apple.com)           │
     │   Returns identity token│
     └────────────┬────────────┘
                  │
     ┌────────────▼────────────────────────┐
     │   Firebase Auth (Google Cloud)      │
     │   - Validates identity token        │
     │   - Creates Firebase User           │
     │   - Returns Firebase credentials    │
     └────────────┬────────────────────────┘
                  │
     ┌────────────▼────────────────────────┐
     │   Cloud Firestore (Google Cloud)    │
     │   - Creates user document           │
     │   - Writes user data                │
     │   - Updates subscriptions           │
     └────────────────────────────────────┘
```

---

## Sequential Flow Diagram

```
User Taps Apple Button
        │
        ▼
┌─────────────────────────┐
│ AuthCubit.signInWithApple()
│ emit(AuthLoading)
│ Call: AuthRepository
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────────────────────────────┐
│ AuthRepository.signInWithApple()               │
├─────────────────────────────────────────────────┤
│                                                 │
│ ✓ Check availability                           │
│   └─ if (!available) throw Exception          │
│                                                 │
│ ✓ Generate Nonce (32 random char)             │
│   └─ _generateNonce()                         │
│                                                 │
│ ✓ Hash Nonce (SHA256)                         │
│   └─ _sha256ofString(nonce)                   │
│                                                 │
│ ✓ Request Apple ID                            │
│   └─ SignInWithApple.getAppleIDCredential()   │
│      (Shows Apple Sign-In Sheet)              │
│                                                 │
│ ✓ Extract Identity Token                      │
│   └─ if (identityToken == null) throw Err    │
│                                                 │
│ ✓ Create OAuth Credential                    │
│   └─ OAuthProvider('apple.com').credential() │
│                                                 │
│ ✓ Sign in to Firebase                        │
│   └─ firebaseAuth.signInWithCredential()     │
│                                                 │
│ ✓ Get Firebase User                          │
│   └─ UserCredential.user                     │
│                                                 │
│ ✓ Upsert User Document                       │
│   └─ _upsertSignedInUser()                   │
│      - Check if exists, update                │
│      - If new, create + assign role          │
│      - Subscribe to notifications            │
│                                                 │
└────────────┬────────────────────────────────────┘
             │
             ▼ Return UserModel
┌─────────────────────────┐
│ AuthCubit.signInWithApple()
│ emit(Authenticated(user))
│ Navigation.pop()
└─────────────────────────┘
             │
             ▼
      User Logged In ✅
```

---

## Data Flow

```
┌──────────────────────────────────────────────────────────┐
│ AUTHENTICATION FLOW DATA                                  │
├──────────────────────────────────────────────────────────┤
│                                                            │
│ 1. NONCE (Random String)                                 │
│    Generated: 32 random characters                        │
│    Used for: CSRF protection                             │
│    Flow: Client → Apple → Firebase                       │
│                                                            │
│ 2. HASHED NONCE (SHA256)                                 │
│    Generated: SHA256(nonce)                              │
│    Sent to: Apple Sign-In request                        │
│    Verified: Firebase verifies against identity token    │
│                                                            │
│ 3. IDENTITY TOKEN (JWT)                                  │
│    From: Apple servers                                    │
│    Contains: User ID, email, name, timestamp             │
│    Encoded: Base64 signed JWT                            │
│    Sent to: Firebase                                      │
│                                                            │
│ 4. FIREBASE USER                                         │
│    UID: Unique Firebase user ID                          │
│    Email: From Apple credential                          │
│    DisplayName: From Apple credential                    │
│    PhotoURL: Empty (Apple doesn't provide)              │
│                                                            │
│ 5. USER DOCUMENT (Firestore)                             │
│    UID: user.uid (Firebase UID)                          │
│    Email: apple email or synthetic                       │
│    DisplayName: From Apple data                          │
│    Role: Determined by _determineUserRole()             │
│    Status: Active                                         │
│                                                            │
└──────────────────────────────────────────────────────────┘
```

---

## Error Points & Debugging

```
┌─────────────────────────────────────────────────────────┐
│ WHERE ERRORS CAN HAPPEN & HOW TO DEBUG                 │
├─────────────────────────────────────────────────────────┤
│                                                          │
│ POINT 1: isAvailable() returns false                   │
│ ├─ Cause: Not iOS/macOS, or feature disabled           │
│ ├─ Console: "🍎 [Apple Sign-In] ERROR: not available" │
│ └─ Fix: Use real iOS device                            │
│                                                          │
│ POINT 2: Apple sheet doesn't appear                   │
│ ├─ Cause: Device not logged into iCloud                │
│ ├─ Console: "🍎 [Apple Sign-In] Requesting..."        │
│ └─ Fix: Sign in to Apple ID in Settings                │
│                                                          │
│ POINT 3: Missing identity token                       │
│ ├─ Cause: Nonce mismatch or Apple error                │
│ ├─ Console: "Missing identity token from Apple"        │
│ └─ Fix: Check Team ID & Bundle ID match                │
│                                                          │
│ POINT 4: Firebase auth fails                          │
│ ├─ Cause: Invalid identity token or App Check blocked  │
│ ├─ Console: "FirebaseAuthException: {message}"         │
│ └─ Fix: Disable App Check on iOS temporarily           │
│                                                          │
│ POINT 5: User document not created                    │
│ ├─ Cause: Firestore rules deny write                   │
│ ├─ Console: "Permission denied in Firestore"           │
│ └─ Fix: Update firestore.rules to allow user create   │
│                                                          │
│ POINT 6: Timeout (slow response)                      │
│ ├─ Cause: Firestore warm-up not done                   │
│ ├─ Console: "Timeout waiting for..."                   │
│ └─ Fix: Check internet, or app warm-up                 │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## Environment Configuration

```
┌──────────────────────────────────────────────────────────┐
│ REQUIRED CONFIGURATIONS                                  │
├──────────────────────────────────────────────────────────┤
│                                                            │
│ iOS/Xcode:                                               │
│ ├─ Bundle ID: com.mallawy.clinicalsystem                 │
│ ├─ Team ID: Your Apple Team                              │
│ ├─ Capability: Sign in with Apple ✓                      │
│ ├─ Entitlements: com.apple.developer.applesignin ✓      │
│ ├─ Deployment Target: 13.0+ (has 14.0 ✓)               │
│ └─ Provisioning Profile: Valid & updated                │
│                                                            │
│ Apple Developer Portal:                                  │
│ ├─ App ID: com.mallawy.clinicalsystem                    │
│ ├─ Capability: Sign in with Apple ✓                      │
│ ├─ Provisioning Profile: Updated                         │
│ └─ Certificate: Valid & uploaded                         │
│                                                            │
│ Firebase Console:                                        │
│ ├─ Project: "clinicalsystem"                             │
│ ├─ Authentication: Apple provider                        │
│ ├─ App Check: Enabled (may need special config)          │
│ └─ Firestore Rules: Allow user creation                  │
│                                                            │
│ App Code:                                                │
│ ├─ sign_in_with_apple: ^7.0.1 ✓                         │
│ ├─ firebase_auth: ^5.3.1 ✓                               │
│ ├─ AuthRepository: Implementation ✓                      │
│ ├─ AuthCubit: State management ✓                         │
│ ├─ LoginScreen: Button exists ✓                          │
│ └─ Main.dart: Initialization ✓                           │
│                                                            │
└──────────────────────────────────────────────────────────┘
```

---

## Status Indicators

```
✅ Working Components:
  - Code logic (repository, cubit, widget)
  - Package installation
  - iOS entitlements file
  - Nonce generation & hashing
  - Firebase integration
  
⚠️  Requires Verification:
  - Firebase App Check (likely blocker)
  - Xcode signing & capabilities
  - Team ID configuration
  - Apple Developer Portal settings
  - Provisioning profile

❓ Unknown:
  - Exact error message (see debug logs)
  - Current Xcode configuration
  - Provisioning profile status
```

---

## Quick Commands Reference

```bash
# Check device/simulator
flutter devices

# Run with verbose logging
flutter run -d ios -v

# Open Xcode for capabilities setup
open ios/Runner.xcworkspace

# Clean & rebuild
flutter clean
rm -rf ios/Pods ios/Podfile.lock
flutter pub get
cd ios && pod install && cd ..
flutter run -d ios

# Check Firestore rules
firebase firestore:indexes

# View Firebase console
open "https://console.firebase.google.com/project/clinicalsystem"
```

---

**Last Updated:** May 3, 2026
