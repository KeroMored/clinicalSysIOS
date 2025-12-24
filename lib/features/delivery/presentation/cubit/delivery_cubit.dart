import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/delivery_model.dart';
import '../../data/repositories/delivery_repository.dart';
import 'delivery_state.dart';

class DeliveryCubit extends Cubit<DeliveryState> {
  final DeliveryRepository repository;

  DeliveryCubit(this.repository) : super(DeliveryInitial());

  // Get available deliveries
  void getAvailableDeliveries() {
    emit(DeliveryLoading());
    try {
      repository.getAvailableDeliveries().listen((deliveries) {
        emit(DeliveryLoaded(deliveries));
      });
    } catch (e) {
      emit(DeliveryError(e.toString()));
    }
  }

  // Get pending deliveries
  void getPendingDeliveries() {
    emit(DeliveryLoading());
    try {
      repository.getPendingDeliveries().listen((deliveries) {
        emit(DeliveryLoaded(deliveries));
      });
    } catch (e) {
      emit(DeliveryError(e.toString()));
    }
  }

  // Get all deliveries
  void getAllDeliveries() {
    emit(DeliveryLoading());
    try {
      repository.getAllDeliveries().listen((deliveries) {
        emit(DeliveryLoaded(deliveries));
      });
    } catch (e) {
      emit(DeliveryError(e.toString()));
    }
  }

  // Get delivery by ID
  Future<void> getDeliveryById(String id) async {
    emit(DeliveryLoading());
    try {
      final delivery = await repository.getDeliveryById(id);
      if (delivery != null) {
        emit(DeliveryDetailLoaded(delivery));
      } else {
        emit(DeliveryError('Delivery not found'));
      }
    } catch (e) {
      emit(DeliveryError(e.toString()));
    }
  }

  // Add delivery
  Future<void> addDelivery(DeliveryModel delivery) async {
    try {
      await repository.addDelivery(delivery);
      emit(DeliveryAdded('تمت إضافة الديليفري بنجاح'));
    } catch (e) {
      emit(DeliveryError(e.toString()));
    }
  }

  // Update delivery
  Future<void> updateDelivery(DeliveryModel delivery) async {
    try {
      await repository.updateDelivery(delivery);
      emit(DeliveryUpdated('تم تحديث الديليفري بنجاح'));
    } catch (e) {
      emit(DeliveryError(e.toString()));
    }
  }

  // Approve delivery
  Future<void> approveDelivery(String deliveryId) async {
    try {
      await repository.approveDelivery(deliveryId);
      emit(DeliveryApproved('تمت الموافقة على الديليفري بنجاح'));
    } catch (e) {
      emit(DeliveryError(e.toString()));
    }
  }

  // Reject delivery
  Future<void> rejectDelivery(String deliveryId, String reason) async {
    try {
      await repository.rejectDelivery(deliveryId, reason);
      emit(DeliveryRejected('تم رفض الديليفري'));
    } catch (e) {
      emit(DeliveryError(e.toString()));
    }
  }

  // Delete delivery
  Future<void> deleteDelivery(String deliveryId) async {
    try {
      await repository.deleteDelivery(deliveryId);
      emit(DeliveryDeleted('تم حذف الديليفري بنجاح'));
    } catch (e) {
      emit(DeliveryError(e.toString()));
    }
  }

  // Toggle availability
  Future<void> toggleAvailability(String deliveryId, bool availableNow) async {
    try {
      await repository.toggleAvailability(deliveryId, availableNow);
      emit(DeliveryUpdated('تم تحديث حالة التوفر'));
    } catch (e) {
      emit(DeliveryError(e.toString()));
    }
  }

  // Return delivery to pending
  Future<void> returnToPending(String deliveryId) async {
    try {
      await repository.returnToPending(deliveryId);
      emit(DeliveryUpdated('تم إرجاع الديليفري لقيد الانتظار'));
    } catch (e) {
      emit(DeliveryError(e.toString()));
    }
  }

  // Search deliveries using Firestore queries
  Future<void> searchDeliveries(String query) async {
    emit(DeliveryLoading());
    try {
      final deliveries = await repository.searchDeliveries(query);
      emit(DeliveryLoaded(deliveries));
    } catch (e) {
      emit(DeliveryError(e.toString()));
    }
  }
}
