import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lab_tests_state.dart';

class LabTestsCubit extends Cubit<LabTestsState> {
  LabTestsCubit() : super(LabTestsInitial());

  Future<void> loadStatistics(String laboratoryId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final startOfMonth = DateTime(now.year, now.month, 1);

      // جلب حجوزات الشهر (غير المؤرشفة فقط)
      final monthBookingsSnapshot = await FirebaseFirestore.instance
          .collection('lab_bookings')
          .where('laboratoryId', isEqualTo: laboratoryId)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where('archivedDate', isNull: true) // استثناء المؤرشفة
          .get();

      int todayBookings = 0;
      int monthBookings = monthBookingsSnapshot.docs.length;

      for (var doc in monthBookingsSnapshot.docs) {
        final createdAt = (doc.get('createdAt') as Timestamp).toDate();

        // عد حجوزات اليوم فقط
        if (createdAt.isAfter(startOfDay) && createdAt.isBefore(endOfDay)) {
          todayBookings++;
        }
      }

      final stats = {
        'todayBookings': todayBookings,
        'monthBookings': monthBookings,
      };

      emit(StatisticsLoaded(stats));
    } catch (e) {
      print('خطأ في تحميل الإحصائيات: $e');
      emit(StatisticsLoaded({'todayBookings': 0, 'monthBookings': 0}));
    }
  }
}
