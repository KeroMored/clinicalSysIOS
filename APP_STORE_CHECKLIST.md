# 📋 App Store Submission Checklist

## Pre-Submission Checklist

### 1️⃣ Development Setup
- [x] Flutter project configured
- [x] Firebase integrated
- [x] Google Sign In working
- [x] All features implemented
- [x] No critical bugs
- [x] Tested on physical device

### 2️⃣ iOS Configuration
- [x] Bundle ID set: `com.mallawy.clinicalsystem`
- [x] Display name set: `نظام العيادات`
- [x] Version: 1.0.0
- [x] Build number: 10
- [x] Privacy descriptions added (all in Arabic)
- [x] Localization configured (Arabic + English)
- [x] Encryption flag set correctly

### 3️⃣ Assets & Design
- [ ] **App icon created (1024x1024)** ⚠️ **REQUIRED**
- [ ] All icon sizes generated (21 sizes)
- [ ] Launch screen configured
- [ ] App looks good in Arabic (RTL)
- [ ] All images optimized
- [ ] Colors consistent with branding

### 4️⃣ Apple Developer Account
- [ ] **Apple Developer Program enrollment ($99/year)** ⚠️ **REQUIRED**
- [ ] Payment method added
- [ ] Account verified
- [ ] Developer profile complete

### 5️⃣ Xcode Setup
- [ ] **Xcode installed on Mac** ⚠️ **REQUIRED**
- [ ] Runner.xcworkspace opens successfully
- [ ] Signing & Capabilities configured
- [ ] Team selected
- [ ] Provisioning profile created
- [ ] No Xcode warnings/errors

### 6️⃣ Testing
- [ ] App runs on physical iPhone/iPad
- [ ] Google Sign In tested
- [ ] Location services tested
- [ ] Camera/Photos tested
- [ ] Push notifications tested
- [ ] All screens navigable
- [ ] No crashes
- [ ] Performance acceptable
- [ ] Memory usage reasonable

### 7️⃣ App Store Connect Setup
- [ ] **App created in App Store Connect** ⚠️ **REQUIRED**
- [ ] App name: نظام العيادات
- [ ] Bundle ID matches: `com.mallawy.clinicalsystem`
- [ ] Category: Medical
- [ ] Content rating set

### 8️⃣ App Store Listing
- [ ] **App description written (Arabic)** ⚠️ **REQUIRED**
- [ ] Keywords added
- [ ] **Support URL added** ⚠️ **REQUIRED**
- [ ] **Privacy policy URL added** ⚠️ **REQUIRED**
- [ ] Marketing URL (optional)
- [ ] Promotional text
- [ ] Pricing set (Free)
- [ ] Availability/territories selected

### 9️⃣ Screenshots & Media
- [ ] **iPhone 6.7" screenshots (1290x2796)** ⚠️ **REQUIRED**
  - [ ] Main screen
  - [ ] Clinics list
  - [ ] Pharmacy screen
  - [ ] Map/location
  - [ ] Profile screen
- [ ] **iPhone 6.5" screenshots (1242x2688)** ⚠️ **REQUIRED**
- [ ] **iPhone 5.5" screenshots (1242x2208)** ⚠️ **REQUIRED**
- [ ] iPad screenshots (optional)
- [ ] App preview video (optional)

### 🔟 App Privacy
- [ ] **Privacy policy created** ⚠️ **REQUIRED**
- [ ] Privacy policy hosted online
- [ ] Privacy details added in App Store Connect:
  - [ ] Contact Info (Email, Name)
  - [ ] Location (Precise Location)
  - [ ] User Content (Photos)
  - [ ] Identifiers (User ID)
  - [ ] Usage Data (Analytics)
- [ ] Data usage purposes declared
- [ ] Third-party partners listed (Google/Firebase)

### 1️⃣1️⃣ Review Information
- [ ] **Contact info provided** ⚠️ **REQUIRED**
  - [ ] First name
  - [ ] Last name
  - [ ] Phone number
  - [ ] Email address
- [ ] **Test account credentials** ⚠️ **REQUIRED IF LOGIN REQUIRED**
  - [ ] Email: ________________
  - [ ] Password: ________________
- [ ] Notes for reviewer (Arabic + English)
- [ ] Demo video/instructions (if complex)

### 1️⃣2️⃣ Build & Upload
- [ ] Project cleaned (`flutter clean`)
- [ ] Dependencies updated (`flutter pub get`)
- [ ] iOS pods updated (`cd ios && pod install`)
- [ ] **Archive created in Xcode** ⚠️ **REQUIRED**
- [ ] Archive validated
- [ ] **Build uploaded to App Store Connect** ⚠️ **REQUIRED**
- [ ] Processing completed
- [ ] Build selected for version

### 1️⃣3️⃣ Final Checks
- [ ] All fields in App Store Connect completed
- [ ] No placeholder content
- [ ] Screenshots match actual app
- [ ] Description accurate
- [ ] Test credentials work
- [ ] Privacy policy accessible
- [ ] Support URL working
- [ ] Age rating appropriate
- [ ] Content rights verified

### 1️⃣4️⃣ Submit
- [ ] **"Add for Review" clicked** ⚠️ **FINAL STEP**
- [ ] Export compliance answered
- [ ] Content rights confirmed
- [ ] Advertising identifier (IDFA) usage declared
- [ ] **"Submit to App Review" clicked** 🚀

---

## Post-Submission Checklist

### After Submission
- [ ] Status: "Waiting for Review" confirmed
- [ ] Email confirmation received
- [ ] Team notified
- [ ] Monitor App Store Connect daily
- [ ] Prepare for possible rejection

### If In Review
- [ ] Monitor status changes
- [ ] Be ready to respond quickly
- [ ] Have team available for questions

### If Approved ✅
- [ ] Celebrate! 🎉
- [ ] Release app (or schedule release)
- [ ] Verify app appears in App Store
- [ ] Download and test from App Store
- [ ] Share with team
- [ ] Announce on social media
- [ ] Monitor reviews
- [ ] Monitor crash reports
- [ ] Plan first update

### If Rejected ❌
- [ ] Read rejection message carefully
- [ ] Understand the issues
- [ ] Make required changes
- [ ] Update build number
- [ ] Create new archive
- [ ] Upload new build
- [ ] Reply in Resolution Center (if needed)
- [ ] Resubmit

---

## Quick Reference

### Critical Files
```
📁 ios/Runner/
  ├── Info.plist ✅ (Configured)
  ├── Assets.xcassets/
  │   └── AppIcon.appiconset/ ⚠️ (Need real icons)
  └── GoogleService-Info.plist ✅ (Firebase)

📁 ios/
  ├── Runner.xcworkspace ✅ (Open this in Xcode)
  └── Runner.xcodeproj/ ✅ (Configured)

📄 pubspec.yaml ✅ (Version: 1.0.0+10)
```

### Important URLs
- **App Store Connect:** https://appstoreconnect.apple.com/
- **Developer Portal:** https://developer.apple.com/
- **TestFlight:** https://testflight.apple.com/
- **Your GitHub Repo:** https://github.com/KeroMored/clinicalSys

### Version Info
- **Current Version:** 1.0.0
- **Current Build:** 10
- **Bundle ID:** com.mallawy.clinicalsystem
- **Display Name:** نظام العيادات

---

## Time Estimates

| Task | Time Required |
|------|---------------|
| Create app icon | 1-4 hours |
| Take screenshots | 2-4 hours |
| Write descriptions | 1-2 hours |
| Create privacy policy | 1-2 hours |
| Set up App Store Connect | 1-2 hours |
| Create archive & upload | 1 hour |
| TestFlight testing | 1-3 days |
| App Store review | 1-2 days |
| **TOTAL** | **5-10 days** |

---

## Common Issues & Solutions

### ❓ "I don't have a Mac"
**Solution:** 
- Use a cloud Mac service (MacStadium, MacinCloud)
- Borrow a Mac from friend/colleague
- Use Mac at Apple Store/library
- Consider Android first (can build on Windows)

### ❓ "Archive fails in Xcode"
**Solution:**
```bash
cd ios
rm -rf build/ Pods/ Podfile.lock
pod install --repo-update
cd ..
flutter clean
flutter pub get
```

### ❓ "Code signing error"
**Solution:**
- Add Apple Developer account in Xcode Preferences
- Select your team in Signing & Capabilities
- Try "Automatically manage signing"

### ❓ "Upload fails"
**Solution:**
- Check bundle ID matches App Store Connect
- Verify version number is higher than previous
- Try using Transporter app instead

### ❓ "App rejected"
**Solution:**
- Read rejection message carefully
- Fix ALL issues mentioned
- Increment build number
- Create new archive
- Upload and resubmit

---

## Priority Actions

### TODAY 🔥
1. Create app icon (1024x1024 PNG)
2. Generate all icon sizes
3. Take screenshots
4. Write app description

### THIS WEEK 📅
1. Set up App Store Connect
2. Create privacy policy
3. Configure Xcode signing
4. Test on physical device
5. Create archive
6. Upload to TestFlight

### NEXT WEEK 🎯
1. TestFlight testing
2. Fix any critical bugs
3. Final screenshot review
4. Submit for App Store review

---

## Help & Resources

### Need Help With
- **Icons:** See `APP_ICON_GUIDE.md`
- **Deployment:** See `IOS_APP_STORE_DEPLOYMENT_GUIDE.md`
- **Overview:** See `APP_STORE_READY.md`

### Contact
- **Apple Support:** developer.apple.com/support
- **Flutter Issues:** github.com/flutter/flutter/issues

---

**Last Updated:** December 24, 2025

✅ = Completed
⚠️ = Required before submission
[ ] = Not yet done

**Print this checklist and check off items as you complete them!**
