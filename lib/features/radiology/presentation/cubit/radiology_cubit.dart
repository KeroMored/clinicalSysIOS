import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/radiology_model.dart';
import '../../data/repositories/radiology_repository.dart';
import 'radiology_state.dart';

class RadiologyCubit extends Cubit<RadiologyState> {
  final RadiologyRepository _repository;
  StreamSubscription? _radiologySubscription;

  RadiologyCubit(this._repository) : super(RadiologyInitial());

  // Load all approved radiology centers
  void loadApprovedRadiologyCenters() {
    emit(RadiologyLoading());
    _radiologySubscription?.cancel();
    _radiologySubscription = _repository.getApprovedRadiologyCenters().listen(
      (centers) {
        emit(RadiologyLoaded(centers));
      },
      onError: (error) {
        emit(RadiologyError('فشل في تحميل مراكز الأشعة: $error'));
      },
    );
  }

  // Load all radiology centers (for admin)
  void loadAllRadiologyCenters() {
    emit(RadiologyLoading());
    _radiologySubscription?.cancel();
    _radiologySubscription = _repository.getAllRadiologyCenters().listen(
      (centers) {
        emit(RadiologyLoaded(centers));
      },
      onError: (error) {
        emit(RadiologyError('فشل في تحميل مراكز الأشعة: $error'));
      },
    );
  }

  // Load pending radiology centers (for admin approval)
  void loadPendingRadiologyCenters() {
    emit(RadiologyLoading());
    _radiologySubscription?.cancel();
    _radiologySubscription = _repository.getPendingRadiologyCenters().listen(
      (centers) {
        emit(RadiologyPendingLoaded(centers));
      },
      onError: (error) {
        emit(RadiologyError('فشل في تحميل طلبات الموافقة: $error'));
      },
    );
  }

  // Load radiology center by owner email
  void loadRadiologyCenterByOwner(String email) {
    emit(RadiologyLoading());
    _radiologySubscription?.cancel();
    _radiologySubscription = _repository
        .getRadiologyCenterByOwnerEmail(email)
        .listen(
          (center) {
            if (center != null) {
              emit(RadiologyCenterDetailLoaded(center));
            } else {
              emit(RadiologyError('لم يتم العثور على مركز الأشعة'));
            }
          },
          onError: (error) {
            emit(RadiologyError('فشل في تحميل بيانات مركز الأشعة: $error'));
          },
        );
  }

  // Search radiology centers
  Future<void> searchRadiologyCenters(String query) async {
    if (query.isEmpty) {
      loadApprovedRadiologyCenters();
      return;
    }

    try {
      emit(RadiologyLoading());
      final results = await _repository.searchRadiologyCenters(query);
      emit(RadiologySearchLoaded(results, query));
    } catch (e) {
      emit(RadiologyError('فشل في البحث: $e'));
    }
  }

  // Filter by governorate
  void filterByGovernorate(String governorate) {
    emit(RadiologyLoading());
    _radiologySubscription?.cancel();
    _radiologySubscription = _repository
        .getRadiologyCentersByGovernorate(governorate)
        .listen(
          (centers) {
            emit(RadiologyFilteredByGovernorate(centers, governorate));
          },
          onError: (error) {
            emit(RadiologyError('فشل في تصفية مراكز الأشعة: $error'));
          },
        );
  }

  // Filter by service
  void filterByService(String service) {
    emit(RadiologyLoading());
    _radiologySubscription?.cancel();
    _radiologySubscription = _repository
        .getRadiologyCentersByService(service)
        .listen(
          (centers) {
            emit(RadiologyFilteredByService(centers, service));
          },
          onError: (error) {
            emit(RadiologyError('فشل في تصفية مراكز الأشعة: $error'));
          },
        );
  }

  // Load home visit radiology centers
  void loadHomeVisitRadiologyCenters() {
    emit(RadiologyLoading());
    _radiologySubscription?.cancel();
    _radiologySubscription = _repository.getHomeVisitRadiologyCenters().listen(
      (centers) {
        emit(RadiologyHomeVisitLoaded(centers));
      },
      onError: (error) {
        emit(RadiologyError('فشل في تحميل المراكز: $error'));
      },
    );
  }

  // Add radiology center
  Future<void> addRadiologyCenter(RadiologyModel radiology) async {
    try {
      emit(RadiologyActionLoading());
      await _repository.addRadiologyCenter(radiology);
      emit(RadiologyActionSuccess('تم إضافة مركز الأشعة بنجاح'));
      loadPendingRadiologyCenters();
    } catch (e) {
      emit(RadiologyError('فشل في إضافة مركز الأشعة: $e'));
    }
  }

  // Update radiology center
  Future<void> updateRadiologyCenter(RadiologyModel radiology) async {
    try {
      emit(RadiologyActionLoading());
      await _repository.updateRadiologyCenter(radiology);
      emit(RadiologyActionSuccess('تم تحديث مركز الأشعة بنجاح'));
    } catch (e) {
      emit(RadiologyError('فشل في تحديث مركز الأشعة: $e'));
    }
  }

  // Delete radiology center
  Future<void> deleteRadiologyCenter(String id) async {
    try {
      emit(RadiologyActionLoading());
      await _repository.deleteRadiologyCenter(id);
      emit(RadiologyActionSuccess('تم حذف مركز الأشعة بنجاح'));
    } catch (e) {
      emit(RadiologyError('فشل في حذف مركز الأشعة: $e'));
    }
  }

  // Approve radiology center
  Future<void> approveRadiologyCenter(String id, {String? notes}) async {
    try {
      emit(RadiologyActionLoading());
      await _repository.approveRadiologyCenter(id, notes: notes);
      emit(RadiologyActionSuccess('تمت الموافقة على مركز الأشعة بنجاح'));
      loadPendingRadiologyCenters();
    } catch (e) {
      emit(RadiologyError('فشل في الموافقة على مركز الأشعة: $e'));
    }
  }

  // Reject radiology center
  Future<void> rejectRadiologyCenter(String id, String notes) async {
    try {
      emit(RadiologyActionLoading());
      await _repository.rejectRadiologyCenter(id, notes);
      emit(RadiologyActionSuccess('تم رفض مركز الأشعة'));
      loadPendingRadiologyCenters();
    } catch (e) {
      emit(RadiologyError('فشل في رفض مركز الأشعة: $e'));
    }
  }

  // Toggle active status
  Future<void> toggleActiveStatus(String id, bool isActive) async {
    try {
      emit(RadiologyActionLoading());
      await _repository.toggleActiveStatus(id, isActive);
      emit(
        RadiologyActionSuccess(
          isActive ? 'تم تفعيل مركز الأشعة' : 'تم إيقاف مركز الأشعة',
        ),
      );
    } catch (e) {
      emit(RadiologyError('فشل في تغيير حالة مركز الأشعة: $e'));
    }
  }

  // Return to pending status
  Future<void> returnToPending(String id) async {
    try {
      emit(RadiologyActionLoading());
      await _repository.returnRadiologyToPending(id);
      emit(RadiologyActionSuccess('تم إرجاع المركز لقيد الانتظار'));
      loadAllRadiologyCenters();
    } catch (e) {
      emit(RadiologyError('فشل في إرجاع المركز: $e'));
    }
  }

  // Load approved centers for admin (with filter)
  void loadApprovedRadiologyCentersForAdmin() {
    emit(RadiologyLoading());
    _radiologySubscription?.cancel();
    _radiologySubscription = _repository
        .getApprovedRadiologyCentersForAdmin()
        .listen(
          (centers) {
            emit(RadiologyLoaded(centers));
          },
          onError: (error) {
            emit(RadiologyError('فشل في تحميل مراكز الأشعة: $error'));
          },
        );
  }

  @override
  Future<void> close() {
    _radiologySubscription?.cancel();
    return super.close();
  }
}
