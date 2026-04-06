# Phone Numbers Save Fix

## Problem
When adding a new pharmacy through the admin panel, multiple phone numbers added via the "إضافة رقم" button were not being saved to the database. Only the first phone number was saved.

## Root Cause
- `PharmacyRequestModel` had a single `String phone` field instead of `List<String> phones`
- The form submission logic in `add_pharmacy_screen.dart` only collected the first phone number: `phone: _phoneControllers[0].text`
- Even though the UI allowed adding up to 5 phone numbers via `_phoneControllers` list, they were not being sent to the database

## Solution

### 1. Updated Data Model
**File:** `lib/features/admin/data/models/pharmacy_request_model.dart`

Changed:
```dart
final String phone;
```

To:
```dart
final List<String> phones;
```

Updated:
- Constructor parameter
- `fromJson` method with backward compatibility (supports both `phones` list and old `phone` string)
- `toJson` method to save as list
- `copyWith` method parameter

### 2. Updated Form Submission
**File:** `lib/features/admin/presentation/screens/add_pharmacy_screen.dart`

Added logic to collect ALL phone numbers:
```dart
// Collect all non-empty phone numbers
final phonesList = _phoneControllers
    .map((controller) => controller.text.trim())
    .where((phone) => phone.isNotEmpty)
    .toList();

final request = PharmacyRequestModel(
  // ...
  phones: phonesList,
  whatsapp: _whatsappController.text.isNotEmpty 
      ? _whatsappController.text 
      : (phonesList.isNotEmpty ? phonesList[0] : ''),
);
```

### 3. Updated Repository
**File:** `lib/features/admin/data/repositories/admin_repository.dart`

Changed:
```dart
phones: [request.phone], // تحويل الرقم الواحد إلى قائمة
```

To:
```dart
phones: request.phones,
```

Also updated two methods that read pharmacy data:
- `getPendingPharmacyRequests()`
- `getPharmacyRequestsByStatus()`

Both now support reading `phones` list with backward compatibility for old `phone` field.

### 4. Updated UI Display
**File:** `lib/features/admin/presentation/widgets/pharmacy_request_card.dart`

Shows first phone number:
```dart
Text(
  request.phones.isNotEmpty ? request.phones[0] : 'لا يوجد',
  style: const TextStyle(fontSize: 14),
),
```

**File:** `lib/features/admin/presentation/screens/pharmacy_request_details_screen.dart`

Shows all phone numbers separated by " - ":
```dart
_buildInfoRow(Icons.phone, 'هاتف الصيدلية', 
    request.phones.isNotEmpty ? request.phones.join(' - ') : 'لا يوجد'),
```

## Backward Compatibility
The fix includes backward compatibility to handle old pharmacy data that has `phone` instead of `phones`:

```dart
phones: json['phones'] != null
    ? List<String>.from(json['phones'])
    : (json['phone'] != null ? [json['phone']] : []),
```

This ensures:
- Old pharmacies with single `phone` field still work
- New pharmacies save multiple phones properly
- No data migration needed

## Testing
To test the fix:

1. Go to Admin Panel → إضافة صيدلية
2. Fill in pharmacy details
3. Click "إضافة رقم" to add multiple phone numbers
4. Submit the form
5. Check the pharmacy details - all phone numbers should be saved
6. View the pharmacy in the list - first phone number should be displayed
7. Open pharmacy details - all phone numbers should be shown separated by " - "

## Files Modified
- `lib/features/admin/data/models/pharmacy_request_model.dart`
- `lib/features/admin/presentation/screens/add_pharmacy_screen.dart`
- `lib/features/admin/data/repositories/admin_repository.dart`
- `lib/features/admin/presentation/widgets/pharmacy_request_card.dart`
- `lib/features/admin/presentation/screens/pharmacy_request_details_screen.dart`

## Date
2025-01-XX
