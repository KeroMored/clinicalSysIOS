import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/visit_model.dart';
import '../../data/repositories/visit_repository.dart';

// States
abstract class VisitState extends Equatable {
  @override
  List<Object?> get props => [];
}

class VisitInitial extends VisitState {}

class VisitLoading extends VisitState {}

class VisitLoaded extends VisitState {
  final List<VisitModel> visits;

  VisitLoaded(this.visits);

  @override
  List<Object?> get props => [visits];
}

class VisitActionLoading extends VisitState {}

class VisitActionSuccess extends VisitState {
  final String message;

  VisitActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class VisitImageUploading extends VisitState {}

class VisitImageUploaded extends VisitState {
  final String imageUrl;

  VisitImageUploaded(this.imageUrl);

  @override
  List<Object?> get props => [imageUrl];
}

class VisitError extends VisitState {
  final String message;

  VisitError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class VisitCubit extends Cubit<VisitState> {
  final VisitRepository _repository;
  StreamSubscription? _visitsSubscription;

  VisitCubit(this._repository) : super(VisitInitial());

  // تحميل كشوفات مريض معين
  void loadVisitsByPatient(String patientId) {
    emit(VisitLoading());
    _visitsSubscription?.cancel();
    _visitsSubscription = _repository
        .getVisitsByPatient(patientId)
        .listen(
          (visits) => emit(VisitLoaded(visits)),
          onError: (e) =>
              emit(VisitError('فشل في تحميل الكشوفات: ${e.toString()}')),
        );
  }

  // تحميل كشوفات عيادة معينة
  void loadVisitsByClinic(String clinicId) {
    emit(VisitLoading());
    _visitsSubscription?.cancel();
    _visitsSubscription = _repository
        .getVisitsByClinic(clinicId)
        .listen(
          (visits) => emit(VisitLoaded(visits)),
          onError: (e) =>
              emit(VisitError('فشل في تحميل الكشوفات: ${e.toString()}')),
        );
  }

  // إضافة كشف جديد
  Future<void> addVisit(VisitModel visit) async {
    try {
      emit(VisitActionLoading());
      await _repository.addVisit(visit);
      emit(VisitActionSuccess('تم إضافة الكشف بنجاح'));
    } catch (e) {
      emit(VisitError('فشل في إضافة الكشف: ${e.toString()}'));
    }
  }

  // تحديث كشف
  Future<void> updateVisit(String visitId, Map<String, dynamic> updates) async {
    try {
      emit(VisitActionLoading());
      await _repository.updateVisit(visitId, updates);
      emit(VisitActionSuccess('تم تحديث الكشف بنجاح'));
    } catch (e) {
      emit(VisitError('فشل في تحديث الكشف: ${e.toString()}'));
    }
  }

  // حذف كشف
  Future<void> deleteVisit(String visitId) async {
    try {
      emit(VisitActionLoading());
      await _repository.deleteVisit(visitId);
      emit(VisitActionSuccess('تم حذف الكشف بنجاح'));
    } catch (e) {
      emit(VisitError('فشل في حذف الكشف: ${e.toString()}'));
    }
  }

  // رفع صورة الروشتة
  Future<String?> uploadPrescriptionImage(
    File imageFile,
    String visitId,
  ) async {
    try {
      emit(VisitImageUploading());
      final imageUrl = await _repository.uploadPrescriptionImage(
        imageFile,
        visitId,
      );
      emit(VisitImageUploaded(imageUrl));
      return imageUrl;
    } catch (e) {
      emit(VisitError('فشل في رفع صورة الروشتة: ${e.toString()}'));
      return null;
    }
  }

  // حذف صورة الروشتة
  Future<void> deletePrescriptionImage(String imageUrl) async {
    try {
      await _repository.deletePrescriptionImage(imageUrl);
    } catch (e) {
      emit(VisitError('فشل في حذف صورة الروشتة: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _visitsSubscription?.cancel();
    return super.close();
  }
}
