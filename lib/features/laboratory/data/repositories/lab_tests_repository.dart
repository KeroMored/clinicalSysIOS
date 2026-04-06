import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository for lab tests data operations
/// Note: Currently, lab test operations are handled directly in LabTestsCubit
/// This file exists for architectural consistency
class LabTestsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get lab bookings statistics for a laboratory
  Future<Map<String, dynamic>> getLabStatistics(String laboratoryId) async {
    try {
      final today = DateTime.now();
      final startOfMonth = DateTime(today.year, today.month, 1);

      final bookingsSnapshot = await _firestore
          .collection('lab_bookings')
          .where('laboratoryId', isEqualTo: laboratoryId)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .get();

      int totalBookings = bookingsSnapshot.docs.length;
      int confirmedCount = 0;
      int completedCount = 0;
      int pendingCount = 0;

      for (var doc in bookingsSnapshot.docs) {
        final status = doc.get('status') as String?;
        if (status == 'confirmed') {
          confirmedCount++;
        } else if (status == 'completed') {
          completedCount++;
        } else if (status == 'pending') {
          pendingCount++;
        }
      }

      return {
        'totalBookings': totalBookings,
        'confirmedBookings': confirmedCount,
        'completedBookings': completedCount,
        'pendingBookings': pendingCount,
      };
    } catch (e) {
      throw Exception('فشل في تحميل الإحصائيات: $e');
    }
  }

  /// Stream lab bookings for a laboratory
  Stream<List<Map<String, dynamic>>> streamLabBookings(String laboratoryId) {
    return _firestore
        .collection('lab_bookings')
        .where('laboratoryId', isEqualTo: laboratoryId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  /// Get appointments needing reminders (for appointment_reminder_service)
  /// Note: This is a placeholder - appointments are currently tracked in lab_bookings collection
  Future<List<dynamic>> getAppointmentsNeedingReminders() async {
    try {
      // For now, return empty list since appointment reminders aren't fully implemented
      // TODO: Implement proper appointment tracking with reminder fields
      return [];
    } catch (e) {
      print('خطأ في جلب المواعيد المحتاجة للتذكير: $e');
      return [];
    }
  }

  /// Mark appointment reminder as sent (for appointment_reminder_service)
  /// Note: This is a placeholder
  Future<void> sendAppointmentReminder(
    String appointmentId,
    String reminderType,
  ) async {
    try {
      // TODO: Implement proper appointment reminder tracking
      print('تم إرسال تذكير $reminderType للموعد $appointmentId');
    } catch (e) {
      print('خطأ في تسجيل إرسال التذكير: $e');
    }
  }
}
