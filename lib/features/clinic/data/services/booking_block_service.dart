import 'package:cloud_firestore/cloud_firestore.dart';

class BookingBlockService {
  static const String _blocksCollection = 'booking_blocks';
  static const int _defaultMaxNoShows = 3;

  final FirebaseFirestore _firestore;

  BookingBlockService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<bool> isPatientBlocked(String patientPhone) async {
    final normalizedPhone = _normalizePhone(patientPhone);
    if (normalizedPhone.isEmpty) return false;

    final doc = await _firestore
        .collection(_blocksCollection)
        .doc(normalizedPhone)
        .get();

    if (!doc.exists) return false;

    final data = doc.data()!;
    final blockedUntil = data['blockedUntil'] as Timestamp?;

    if (blockedUntil == null) return false;

    return blockedUntil.toDate().isAfter(DateTime.now());
  }

  Future<Map<String, dynamic>?> getBlockInfo(String patientPhone) async {
    final normalizedPhone = _normalizePhone(patientPhone);
    if (normalizedPhone.isEmpty) return null;

    final doc = await _firestore
        .collection(_blocksCollection)
        .doc(normalizedPhone)
        .get();

    if (!doc.exists) return null;

    return doc.data();
  }

  Future<void> recordNoShow({
    required String patientPhone,
    required String patientName,
    required String clinicId,
    required String bookingId,
    int maxNoShows = _defaultMaxNoShows,
    int blockDays = 30,
  }) async {
    final normalizedPhone = _normalizePhone(patientPhone);
    if (normalizedPhone.isEmpty) return;

    final docRef = _firestore.collection(_blocksCollection).doc(normalizedPhone);
    final doc = await docRef.get();

    if (doc.exists) {
      final data = doc.data()!;
      final noShows = List<Map<String, dynamic>>.from(data['noShows'] ?? []);
      final currentBlockEnd = data['blockedUntil'] as Timestamp?;

      final alreadyCounted = noShows.any(
        (entry) => entry['bookingId'] == bookingId,
      );
      if (alreadyCounted) return;

      noShows.add({
        'bookingId': bookingId,
        'clinicId': clinicId,
        'patientName': patientName,
        'date': Timestamp.now(),
      });

      final noShowsSinceLastBlock = noShows.where((entry) {
        if (currentBlockEnd == null) return true;
        return (entry['date'] as Timestamp)
            .toDate()
            .isAfter(currentBlockEnd.toDate());
      }).toList().length;

      if (noShowsSinceLastBlock >= maxNoShows) {
        final blockedUntil = Timestamp.fromDate(
          DateTime.now().add(Duration(days: blockDays)),
        );

        await docRef.set({
          'patientPhone': normalizedPhone,
          'patientName': patientName,
          'noShows': noShows,
          'noShowCount': noShows.length,
          'blockedUntil': blockedUntil,
          'blockReason': 'تكرار عدم الحضور ($noShowsSinceLastBlock مرات)',
          'updatedAt': Timestamp.now(),
          'blockHistory': FieldValue.arrayUnion([
            {
              'blockedUntil': blockedUntil,
              'reason': 'تكرار عدم الحضور',
              'count': noShowsSinceLastBlock,
              'date': Timestamp.now(),
            },
          ]),
        }, SetOptions(merge: true));
      } else {
        await docRef.set({
          'patientPhone': normalizedPhone,
          'patientName': patientName,
          'noShows': noShows,
          'noShowCount': noShows.length,
          'blockedUntil': null,
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));
      }
    } else {
      final noShowEntry = {
        'bookingId': bookingId,
        'clinicId': clinicId,
        'patientName': patientName,
        'date': Timestamp.now(),
      };

      await docRef.set({
        'patientPhone': normalizedPhone,
        'patientName': patientName,
        'noShows': [noShowEntry],
        'noShowCount': 1,
        'blockedUntil': null,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    }
  }

  Future<void> unblockPatient(String patientPhone) async {
    final normalizedPhone = _normalizePhone(patientPhone);
    if (normalizedPhone.isEmpty) return;

    await _firestore
        .collection(_blocksCollection)
        .doc(normalizedPhone)
        .update({
          'blockedUntil': null,
          'unblockedAt': Timestamp.now(),
        });
  }

  Future<void> deleteBlock(String patientPhone) async {
    final normalizedPhone = _normalizePhone(patientPhone);
    if (normalizedPhone.isEmpty) return;

    await _firestore
        .collection(_blocksCollection)
        .doc(normalizedPhone)
        .delete();
  }

  Future<List<Map<String, dynamic>>> getBlockedPatients() async {
    final now = Timestamp.now();
    final snapshot = await _firestore
        .collection(_blocksCollection)
        .where('blockedUntil', isGreaterThan: now)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        ...data,
        'id': doc.id,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getNoShowHistory(
    String patientPhone,
  ) async {
    final normalizedPhone = _normalizePhone(patientPhone);
    if (normalizedPhone.isEmpty) return [];

    final doc = await _firestore
        .collection(_blocksCollection)
        .doc(normalizedPhone)
        .get();

    if (!doc.exists) return [];

    final data = doc.data()!;
    final noShows = List<Map<String, dynamic>>.from(data['noShows'] ?? []);
    return noShows;
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }
}
