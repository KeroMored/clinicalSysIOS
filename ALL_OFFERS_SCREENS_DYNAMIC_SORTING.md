# Dynamic Sorting System - Complete Implementation

## Overview
This document describes the complete implementation of the dynamic offer sorting system across **ALL three offer screens** in the Clinical System application.

## ✅ Completed Screens

### 1. Medicine Offers Screen
**File:** `lib/features/medicine_offers/presentation/screens/medicine_offers_screen.dart`
**Purpose:** Display medicine offers with dynamic sorting
**Service:** `OfferSortingService` (wraps GenericOfferSortingService<MedicineOfferModel>)
**Status:** ✅ Complete

### 2. Pharmacy Offers List Screen
**File:** `lib/features/pharmacy/presentation/screens/pharmacy_offers_list_screen.dart`
**Purpose:** Display offers for a single pharmacy with dynamic sorting
**Service:** `PharmacyOfferSortingService` (wraps GenericOfferSortingService<PharmacyOfferModel>)
**Status:** ✅ Complete

### 3. All Offers Screen (General Offers)
**File:** `lib/features/pharmacy/presentation/screens/all_offers_screen.dart`
**Purpose:** Display all offers from all pharmacies (accessed from home → pharmacies → "العروض والخصومات")
**Service:** `PharmacyOfferSortingService` (wraps GenericOfferSortingService<PharmacyOfferModel>)
**Status:** ✅ Complete

## Architecture

### Generic Service Pattern
```dart
// Core interface for sortable offers
abstract class ISortableOffer {
  String get id;
  DateTime get createdAt;
  int get viewsCount;
  String get category;
}

// Generic sorting service (reusable for any offer type)
class GenericOfferSortingService<T extends ISortableOffer> {
  List<T> sortOffers({
    required List<T> offers,
    required int pageNumber,
    required int pageSize,
  });
}
```

### Service Wrappers
- **OfferSortingService:** For MedicineOfferModel
- **PharmacyOfferSortingService:** For PharmacyOfferModel

## Sorting Algorithm

### Weighted Scoring Formula
```
Score = (35% × Recency) + (25% × Engagement) + (20% × Diversity) + (20% × Randomness)
```

### Components
1. **Recency (35%):** Newer offers score higher
2. **Engagement (25%):** Higher viewsCount scores higher
3. **Diversity (20%):** Category distribution balancing
4. **Randomness (20%):** Unpredictable element for variety

## Data Models

### PharmacyOfferModel Updates
```dart
class PharmacyOfferModel implements ISortableOffer {
  final String id;
  final String pharmacyId;
  final String pharmacyName;
  final String title;
  final String description;
  final String notes; // ✨ NEW
  final String imageUrl;
  final List<String> images; // ✨ NEW (multiple images)
  final DateTime createdAt; // ✨ NEW
  final int viewsCount; // ✨ NEW
  final String category; // ✨ NEW
  // ... other fields
}
```

### MedicineOfferModel Updates
```dart
class MedicineOfferModel implements ISortableOffer {
  final String id;
  final DateTime createdAt;
  final int viewsCount; // ✨ NEW
  final String category; // ✨ NEW
  // ... other fields
}
```

## Pagination Strategy

### Two-Level Pagination
```dart
// Level 1: Firestore Fetch
final int _fetchBatchSize = 50; // Fetch 50 offers from Firestore

// Level 2: Display Pagination
final int _displayPageSize = 8; // Display 8 offers per page
```

### Benefits
- ✅ Efficient Firestore queries
- ✅ Smooth scrolling experience
- ✅ Dynamic re-sorting without refetching
- ✅ Better user engagement

## All Offers Screen Implementation

### Key Changes

#### 1. State Variables
```dart
// Before
List<Map<String, dynamic>> _offers = [];
int _pageSize = 10;

// After
final _sortingService = PharmacyOfferSortingService();
final _controlService = AppControlService();
List<PharmacyOfferModel> _allFetchedOffers = [];
List<PharmacyOfferModel> _displayedOffers = [];
bool _showViewsCount = false;
int _currentDisplayPage = 0;
final int _fetchBatchSize = 50;
final int _displayPageSize = 8;
```

#### 2. Data Fetching
```dart
Future<void> _fetchOffersFromFirestore() async {
  // Fetch from 'offers' collection
  Query query = FirebaseFirestore.instance
      .collection('offers')
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(_fetchBatchSize);

  // Map to PharmacyOfferModel
  final newOffers = snapshot.docs
      .map((doc) => PharmacyOfferModel.fromJson({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          }))
      .toList();

  _allFetchedOffers.addAll(newOffers);
}
```

#### 3. Dynamic Sorting
```dart
void _applySortingAndPagination() {
  final sortedOffers = _sortingService.sortOffers(
    offers: _allFetchedOffers,
    pageNumber: 0,
    pageSize: _allFetchedOffers.length,
  );
  
  final endIndex = (_currentDisplayPage + 1) * _displayPageSize;
  _displayedOffers = sortedOffers.take(endIndex).toList();
}
```

#### 4. Views Count Tracking
```dart
Future<void> _incrementViewsCount(String offerId) async {
  await FirebaseFirestore.instance
      .collection('offers')
      .doc(offerId)
      .update({
    'viewsCount': FieldValue.increment(1),
  });
}
```

#### 5. UI Updates
```dart
// Shuffle icon in AppBar
actions: [
  Tooltip(
    message: 'الترتيب ديناميكي',
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.shuffle, color: Colors.white),
    ),
  ),
],

// Offer card with conditional viewsCount
OfferCard(
  offerId: offer.id,
  // ... other fields
  showViewsCount: _showViewsCount,
  viewsCount: offer.viewsCount,
  category: offer.category,
)
```

## Firestore Structure

### app_control Collection
```json
{
  "offers_settings": {
    "showViewsCount": false,
    "updatedAt": "2024-01-15T10:30:00Z"
  }
}
```

### offers Collection (All Pharmacies)
```json
{
  "id": "offer123",
  "pharmacyId": "pharmacy456",
  "pharmacyName": "صيدلية النور",
  "title": "خصم 20% على جميع الأدوية",
  "description": "عرض محدود لفترة قصيرة",
  "notes": "صالح حتى نهاية الشهر",
  "images": [
    "https://storage.googleapis.com/image1.jpg",
    "https://storage.googleapis.com/image2.jpg"
  ],
  "imageUrl": "https://storage.googleapis.com/image1.jpg",
  "createdAt": "2024-01-15T10:00:00Z",
  "viewsCount": 125,
  "category": "أدوية",
  "isActive": true
}
```

### medicine_offers Collection
```json
{
  "id": "medicine_offer123",
  "medicineName": "باراسيتامول",
  "description": "خصم 15%",
  "createdAt": "2024-01-15T10:00:00Z",
  "viewsCount": 89,
  "category": "مسكنات",
  "isActive": true
}
```

## User Flow

### All Offers Screen Access Path
```
Home Screen
  → Pharmacies Section
    → "العروض والخصومات" Button
      → All Offers Screen (all_offers_screen.dart)
```

### Interaction Flow
1. User opens All Offers Screen
2. App loads settings from `app_control/offers_settings`
3. Fetches 50 offers from `offers` collection
4. Applies dynamic sorting algorithm
5. Displays first 8 offers
6. User scrolls → loads more from sorted batch
7. When sorted batch runs out → fetches next 50 from Firestore
8. Repeats sorting and display
9. User taps offer → increments viewsCount

## Benefits of This Implementation

### 1. Code Reusability
- ✅ Generic service works with any offer model
- ✅ Single sorting algorithm across all screens
- ✅ Consistent behavior everywhere

### 2. Performance
- ✅ Efficient Firestore queries (batch fetching)
- ✅ Local sorting (no repeated Firestore calls)
- ✅ Smooth scrolling with pagination

### 3. User Experience
- ✅ Fresh content on every visit (randomness)
- ✅ Relevant offers prioritized (recency + engagement)
- ✅ Diverse categories shown (diversity factor)
- ✅ Visual feedback (shuffle icon)

### 4. Maintainability
- ✅ Clean architecture
- ✅ Type-safe with generics
- ✅ Easy to extend with new offer types
- ✅ Centralized configuration

## Testing the System

### 1. Setup Firestore
```powershell
# Run setup script
.\setup_dynamic_sorting.ps1
```

This creates:
- `app_control/offers_settings` document
- Sample offers with viewsCount and category

### 2. Test Flows

#### Medicine Offers Screen
1. Navigate to Medicine Offers
2. Observe shuffle icon in AppBar
3. Scroll through offers
4. Check sorting changes on refresh

#### Pharmacy Offers List Screen
1. Go to a pharmacy details
2. View its offers
3. Check dynamic sorting works per pharmacy

#### All Offers Screen
1. Home → Pharmacies → "العروض والخصومات"
2. See all pharmacies' offers
3. Verify sorting and pagination
4. Check viewsCount increments on tap

### 3. Verify Settings
```dart
// Toggle viewsCount visibility
await FirebaseFirestore.instance
    .collection('app_control')
    .doc('offers_settings')
    .update({'showViewsCount': true});

// Restart app → viewsCount should be visible on all screens
```

## Migration Notes

### For Existing Offers
Existing offers in Firestore may not have the new fields. The models handle this gracefully:

```dart
// PharmacyOfferModel.fromJson
viewsCount: json['viewsCount'] ?? 0, // defaults to 0
category: json['category'] ?? 'عام', // defaults to 'عام'
createdAt: createdAt ?? DateTime.now(), // uses current time
notes: json['notes'] ?? '', // defaults to empty
images: json['images'] ?? [], // defaults to empty list
```

### Update Existing Data
```javascript
// Firestore console or Cloud Functions
db.collection('offers').get().then(snapshot => {
  snapshot.forEach(doc => {
    doc.ref.update({
      viewsCount: 0,
      category: 'عام',
      notes: '',
      images: [doc.data().imageUrl || '']
    });
  });
});
```

## Troubleshooting

### Issue: Offers not appearing sorted
**Solution:** Check if offers have `createdAt` field. Run migration script.

### Issue: ViewsCount not showing
**Solution:** Check `app_control/offers_settings.showViewsCount` is true.

### Issue: Pagination not working
**Solution:** Verify `_fetchBatchSize` = 50 and `_displayPageSize` = 8.

### Issue: Duplicate offers showing
**Solution:** Check `_lastDocument` cursor is properly maintained.

## Performance Metrics

### Expected Behavior
- **Initial Load:** ~500ms (fetch 50 offers)
- **Sorting:** <50ms (local operation)
- **Pagination:** <10ms (displaying from cache)
- **Refresh:** ~500ms (new Firestore query)

### Firestore Reads
- **First load:** 50 reads
- **Each pagination:** 0 reads (uses cache)
- **Scroll to end:** +50 reads (new batch)
- **Refresh:** 50 reads (new query)

## Future Enhancements

### Potential Improvements
1. **User Preferences:** Remember sorting preferences per user
2. **Smart Categories:** ML-based category suggestions
3. **A/B Testing:** Test different sorting weights
4. **Analytics:** Track which offers perform best
5. **Real-time Updates:** Listen to new offers with StreamBuilder
6. **Predictive Fetching:** Preload next batch before scroll end

## Conclusion

The dynamic sorting system is now **fully implemented** across all three offer screens:
1. ✅ Medicine Offers Screen
2. ✅ Pharmacy Offers List Screen (single pharmacy)
3. ✅ All Offers Screen (all pharmacies)

All screens use the same sorting algorithm, provide smooth pagination, track engagement, and offer a consistent user experience throughout the app.

---

**Last Updated:** 2024-01-15
**Implementation Time:** Complete
**Status:** Production Ready 🚀
