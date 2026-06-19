# Copilot Instructions - Clinical System (ملوي كيور | Mallawi Cure)

## Project Overview
Flutter-based healthcare system for managing clinics, pharmacies, laboratories, radiology centers, nursing services, gyms, rehabilitation centers, and delivery services. Built with Firebase backend (Firestore, Auth, Storage, Messaging). Arabic-first UI with RTL support.

## Architecture

### Feature-First Clean Architecture (without Domain layer)
```
lib/features/{feature_name}/
├── data/
│   ├── models/          # Data models with fromFirestore/toFirestore methods
│   └── repositories/    # Firebase operations, Stream/Future returns
└── presentation/
    ├── cubit/           # State management with Cubit (NOT Bloc)
    │   ├── {feature}_cubit.dart
    │   └── {feature}_state.dart
    ├── screens/         # Full-page widgets
    └── widgets/         # Reusable components
```

**Key Convention:** No domain layer. Repositories directly accessed by Cubits. States are simple classes extending base state class or `Equatable`.

### Core Architecture
- `lib/core/services/` - Cross-feature services (NotificationService, LocationService)
- `lib/core/security/` - SecurityManager, EncryptionService (initialized in main.dart)
- `lib/core/theme/` - AppTheme with gradients (primaryGradient, pharmacyGradient, clinicGradient, etc.)
- `lib/core/widgets/` - Reusable widgets (GradientAppBar, ModernCard, etc.)

## State Management

### Always Use Cubit (Never Bloc)
```dart
class FeatureCubit extends Cubit<FeatureState> {
  final FeatureRepository _repository;
  StreamSubscription? _subscription; // For real-time Firestore
  
  FeatureCubit(this._repository) : super(FeatureInitial());
  
  void loadData() {
    emit(FeatureLoading());
    _subscription?.cancel();
    _subscription = _repository.streamData().listen(
      (data) => emit(FeatureLoaded(data)),
      onError: (e) => emit(FeatureError('فشل: ${e.toString()}')),
    );
  }
  
  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
```

### State Patterns
- Initial: `FeatureInitial`
- Loading: `FeatureLoading` (or `FeatureActionLoading` for specific actions)
- Success: `FeatureLoaded(data)`, `FeatureActionSuccess(message)`
- Error: `FeatureError(message)` - always Arabic messages

### BlocProvider Setup
Global providers in `main.dart` MultiBlocProvider. Per-screen providers use `BlocProvider.value(value: context.read<Cubit>())` when navigating.

## Firebase Integration

### Firestore Collections
- `users`, `pharmacies`, `clinics`, `radiology_centers`, `gyms`, `laboratories`, `rehabilitation_centers`, `nurses`, `deliveries`, `bookings`, `subscriptions`, `pharmacy_requests`, `medicine_offers`
- Approval pattern: `isApproved: bool`, `status: 'approved'|'pending'|'rejected'`, `isActive: bool`

### Repository Pattern
```dart
class FeatureRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Use Streams for real-time data
  Stream<List<Model>> getApprovedItems() {
    return _firestore
        .collection('items')
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Model.fromFirestore(doc)).toList());
  }
  
  // Use Futures for one-time operations
  Future<Model> getById(String id) async {
    final doc = await _firestore.collection('items').doc(id).get();
    return Model.fromFirestore(doc);
  }
}
```

### Optimization - Firestore Warm-up
Main.dart has `_warmUpFirestore()` that pre-loads common collections on app start. Add new collections here for faster first access.

## Authentication & Authorization

### Multi-Role System
- **Admin:** Hardcoded emails in `AuthRepository._adminEmails` (admin@clinicalsystem.com)
- **Pharmacy/Clinic/Owner:** Auto-assigned based on `authEmails` field in place documents
- **User:** Default role for others

### Auth Flow (Google Sign-In only)
1. `AuthRepository.signInWithGoogle()` - FAST path checks user cache first
2. New users: role determined by `_determineUserRole()`, saved to `users` collection
3. Background: pharmacy setup, notification topics subscribed (fire-and-forget)

**CRITICAL:** Never await background operations in auth flow. Use `.then()` for speed.

## Design System

### Theme (AppTheme)
- **Colors:** primaryColor (0xFF00BCD4 - teal), secondaryColor (0xFF1E3A5F - navy)
- **Gradients:** Use `AppTheme.primaryGradient`, `AppTheme.pharmacyGradient`, etc.
- **Widgets:** GradientAppBar, ModernCard, ModernOptionCard (see lib/core/widgets/)

### Arabic-First & RTL
- All text in Arabic, RTL enforced via `Directionality(textDirection: TextDirection.rtl)` in main.dart builder
- `textScaleFactor: 1.0` locked in MediaQuery to prevent system font size changes
- Locale: `ar, EG` with Arabic localizations

### Modern Design Pattern
Cards use gradients + shadows. See `MODERN_DESIGN_APPLICATION_GUIDE.md` for examples. No flat colors on primary elements.

## Notifications

### Firebase Cloud Messaging
- NotificationService initialized in main.dart, handles foreground/background/taps
- Topic-based: `pharmacy_requests` topic for all pharmacies
- Local notifications via flutter_local_notifications for foreground display
- Background handler: `_firebaseMessagingBackgroundHandler` in main.dart

### Doctor of the Day
- Uses awesome_notifications for daily scheduled notifications
- Initialized in main.dart with `DoctorOfTheDayNotification.initialize()`

## Security

### SecurityManager (initialized in main.dart)
- EncryptionService for sensitive data
- SecurityCheckService for device validation (root detection, debugger, emulator)
- `kDebugMode && allowInDebug = true` bypasses checks in dev

## Common Patterns

### Navigation
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BlocProvider.value(
      value: context.read<FeatureCubit>(),
      child: TargetScreen(),
    ),
  ),
);
```

### Search (Firestore limitations)
Use `where('field', isGreaterThanOrEqualTo: query)` + `where('field', isLessThanOrEqualTo: query + '\uf8ff')` for prefix search. Combine results from multiple fields using Map deduplication.

### Error Handling
Always emit Arabic error messages: `emit(FeatureError('فشل في تحميل البيانات: $e'));`

## Development Commands

### Run
```powershell
flutter run  # Default: debug mode
flutter run -d chrome  # Web
flutter run -d windows  # Windows desktop
```

### Build
```powershell
flutter build apk --release  # Android APK
flutter build appbundle --release  # Android App Bundle
```

### Firestore Rules
Edit `firestore.rules`, deploy via Firebase Console or `firebase deploy --only firestore:rules`

## Feature-Specific Notes

### Booking System
- `BookingCubit` for deletion/updates, no repository layer
- Notifications sent via `NotificationService.sendBookingNotification()`

### Pharmacy Status System
- Multi-status: `isApproved`, `status`, `isActive` for granular control
- Pending requests in `pharmacy_requests` collection, approved → `pharmacies` collection

### Subscriptions
- SubscriptionCubit with pagination (pageSize=10), tracks `_allPlaces`, `_hasMoreData`
- Payment records, settings, statistics all separate streams

## Common Pitfalls
- ❌ Don't create domain layer (violates project architecture)
- ❌ Don't use Bloc (only Cubit)
- ❌ Don't use English UI text (Arabic only)
- ❌ Don't await background operations in critical paths (auth, init)
- ❌ Don't forget `_subscription?.cancel()` in Cubit.close()
- ❌ Don't use flat colors (use gradients per design system)
