import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/daily_activity_model.dart';

class DailyActivityRemoteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadDailyEntry({
    required String userId,
    required DailyActivityModel entry,
  }) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_activity')
        .doc(entry.dateKey);

    await docRef.set({
      'dateKey': entry.dateKey,
      'steps': entry.steps,
      'meters': entry.meters,
      'performanceLabel': entry.performanceLabel,
      'updatedAt': Timestamp.fromDate(entry.updatedAt),
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
