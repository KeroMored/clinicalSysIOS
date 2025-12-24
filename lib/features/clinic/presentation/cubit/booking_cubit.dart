import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  BookingCubit() : super(BookingInitial());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// حذف حجز من الداتابيز
  Future<void> deleteBooking(String bookingId) async {
    try {
      emit(BookingDeleting());

      print('🗑️ بدء حذف الحجز - ID: $bookingId');

      // الحذف من Firestore
      await _firestore.collection('bookings').doc(bookingId).delete();

      print('✅ تم حذف الحجز بنجاح - ID: $bookingId');

      emit(BookingDeleted());
    } catch (e) {
      print('❌ خطأ في حذف الحجز: $e');
      emit(BookingError('فشل حذف الحجز: $e'));
    }
  }

  /// تأكيد حجز
  Future<void> confirmBooking(String bookingId) async {
    try {
      emit(BookingUpdating());

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'confirmed',
        'confirmedAt': Timestamp.now(),
      });

      emit(BookingUpdated());
    } catch (e) {
      emit(BookingError('فشل تأكيد الحجز: $e'));
    }
  }

  /// تحديث حالة الحجز إلى "تم الكشف"
  Future<void> markAsCompleted(String bookingId) async {
    try {
      emit(BookingUpdating());

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'completed',
      });

      emit(BookingUpdated());
    } catch (e) {
      emit(BookingError('فشل تحديث الحجز: $e'));
    }
  }
}
