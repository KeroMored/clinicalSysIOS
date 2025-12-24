import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/rehabilitation_center_model.dart';
import '../../data/repositories/rehabilitation_repository.dart';
import 'rehabilitation_state.dart';

class RehabilitationCubit extends Cubit<RehabilitationState> {
  final RehabilitationRepository _repository;

  RehabilitationCubit(this._repository) : super(RehabilitationInitial());

  // Get available centers
  void getAvailableCenters() {
    emit(RehabilitationLoading());
    _repository.getAvailableCenters().listen(
      (centers) {
        emit(RehabilitationLoaded(centers));
      },
      onError: (error) {
        emit(RehabilitationError('فشل في تحميل المراكز: $error'));
      },
    );
  }

  // Get pending centers
  void getPendingCenters() {
    emit(RehabilitationLoading());
    _repository.getPendingCenters().listen(
      (centers) {
        emit(RehabilitationLoaded(centers));
      },
      onError: (error) {
        emit(RehabilitationError('فشل في تحميل المراكز المعلقة: $error'));
      },
    );
  }

  // Get all centers
  void getAllCenters() {
    emit(RehabilitationLoading());
    _repository.getAllCenters().listen(
      (centers) {
        emit(RehabilitationLoaded(centers));
      },
      onError: (error) {
        emit(RehabilitationError('فشل في تحميل جميع المراكز: $error'));
      },
    );
  }

  // Get centers by type
  void getCentersByType(String serviceType) {
    emit(RehabilitationLoading());
    _repository.getCentersByType(serviceType).listen(
      (centers) {
        emit(RehabilitationLoaded(centers));
      },
      onError: (error) {
        emit(RehabilitationError('فشل في تحميل المراكز: $error'));
      },
    );
  }

  // Get centers by governorate
  void getCentersByGovernorate(String governorate) {
    emit(RehabilitationLoading());
    _repository.getCentersByGovernorate(governorate).listen(
      (centers) {
        emit(RehabilitationLoaded(centers));
      },
      onError: (error) {
        emit(RehabilitationError('فشل في تحميل المراكز: $error'));
      },
    );
  }

  // Add center
  Future<void> addCenter(RehabilitationCenterModel center) async {
    emit(RehabilitationLoading());
    try {
      await _repository.addCenter(center);
      emit(RehabilitationAdded('تم إضافة المركز بنجاح وفي انتظار الموافقة'));
    } catch (e) {
      emit(RehabilitationError('فشل في إضافة المركز: $e'));
    }
  }

  // Update center
  Future<void> updateCenter(RehabilitationCenterModel center) async {
    emit(RehabilitationLoading());
    try {
      await _repository.updateCenter(center);
      emit(RehabilitationUpdated('تم تحديث المركز بنجاح'));
    } catch (e) {
      emit(RehabilitationError('فشل في تحديث المركز: $e'));
    }
  }

  // Delete center
  Future<void> deleteCenter(String centerId) async {
    emit(RehabilitationLoading());
    try {
      await _repository.deleteCenter(centerId);
      emit(RehabilitationDeleted('تم حذف المركز بنجاح'));
    } catch (e) {
      emit(RehabilitationError('فشل في حذف المركز: $e'));
    }
  }

  // Approve center
  Future<void> approveCenter(String centerId) async {
    try {
      await _repository.approveCenter(centerId);
      emit(RehabilitationApproved('تمت الموافقة على المركز بنجاح'));
    } catch (e) {
      emit(RehabilitationError('فشل في الموافقة على المركز: $e'));
    }
  }

  // Reject center
  Future<void> rejectCenter(String centerId, String reason) async {
    try {
      await _repository.rejectCenter(centerId, reason);
      emit(RehabilitationRejected('تم رفض المركز'));
    } catch (e) {
      emit(RehabilitationError('فشل في رفض المركز: $e'));
    }
  }

  // Toggle active status
  Future<void> toggleActiveStatus(String centerId, bool isActive) async {
    try {
      await _repository.toggleActiveStatus(centerId, isActive);
      emit(RehabilitationUpdated('تم تحديث حالة المركز'));
    } catch (e) {
      emit(RehabilitationError('فشل في تحديث حالة المركز: $e'));
    }
  }

  // Search centers using Firestore queries
  Future<void> searchCenters(String query) async {
    emit(RehabilitationLoading());
    try {
      final centers = await _repository.searchCenters(query);
      emit(RehabilitationLoaded(centers));
    } catch (e) {
      emit(RehabilitationError('فشل في البحث: $e'));
    }
  }
}
