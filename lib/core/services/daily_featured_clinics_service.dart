import 'package:cloud_firestore/cloud_firestore.dart';

class DailyFeaturedClinicsService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int _dailyClinicsCount = 10;

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static Future<List<String>> getTodayFeaturedClinicIds() async {
    try {
      final todayKey = _todayKey();
      final docRef = _db.collection('daily_featured_clinics').doc(todayKey);
      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['clinicIds'] != null) {
          return List<String>.from(data['clinicIds']);
        }
      }

      final selectedIds = await _selectAndStoreTodayClinics(todayKey);
      return selectedIds;
    } catch (e) {
      print('⚠️ DailyFeaturedClinicsService.getTodayFeaturedClinicIds error: $e');
      return _fallbackSelection();
    }
  }

  static Future<List<String>> _selectAndStoreTodayClinics(
    String todayKey,
  ) async {
    final allClinicsSnapshot = await _db
        .collection('clinics')
        .where('status', isEqualTo: 'approved')
        .where('isActive', isEqualTo: true)
        .get();

    final allClinics = allClinicsSnapshot.docs;

    if (allClinics.isEmpty) {
      return [];
    }

    final scoredClinics = allClinics.map((doc) {
      final data = doc.data();
      final viewsCount = (data['viewsCount'] as num? ?? 0).toInt();
      final lastFeaturedTs = data['lastFeaturedDate'] is Timestamp
          ? data['lastFeaturedDate'] as Timestamp
          : null;
      final daysSinceLastFeatured = lastFeaturedTs != null
          ? DateTime.now().difference(lastFeaturedTs.toDate()).inDays
          : 9999;

      final viewsScore = viewsCount.toDouble();
      final recencyScore = daysSinceLastFeatured.toDouble() * 10;
      final priorityScore = viewsScore - recencyScore;

      return {
        'doc': doc,
        'priorityScore': priorityScore,
      };
    }).toList();

    scoredClinics.sort((a, b) {
      return (a['priorityScore'] as num)
          .compareTo(b['priorityScore'] as num);
    });

    final selectedClinics = scoredClinics.take(_dailyClinicsCount).toList();
    final selectedIds = selectedClinics
        .map((c) => (c['doc'] as QueryDocumentSnapshot).id)
        .toList();

    final today = DateTime.now();
    try {
      await _db.collection('daily_featured_clinics').doc(todayKey).set({
        'date': Timestamp.fromDate(
          DateTime.utc(today.year, today.month, today.day),
        ),
        'clinicIds': selectedIds,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final batch = _db.batch();
      for (final id in selectedIds) {
        final clinicRef = _db.collection('clinics').doc(id);
        batch.update(clinicRef, {
          'lastFeaturedDate': Timestamp.fromDate(today),
        });
      }
      await batch.commit();
      print('✅ Featured clinics stored for $todayKey: $selectedIds');
    } catch (e) {
      print('⚠️ Failed to store featured clinics (falling back): $e');
    }

    return selectedIds;
  }

  static Future<List<String>> _fallbackSelection() async {
    try {
      final allClinicsSnapshot = await _db
          .collection('clinics')
          .where('status', isEqualTo: 'approved')
          .where('isActive', isEqualTo: true)
          .get();

      final allClinics = allClinicsSnapshot.docs;
      if (allClinics.isEmpty) return [];

      allClinics.shuffle();
      return allClinics
          .take(_dailyClinicsCount)
          .map((d) => d.id)
          .toList();
    } catch (e) {
      print('⚠️ Fallback selection also failed: $e');
      return [];
    }
  }
}
