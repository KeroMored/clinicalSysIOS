import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/patient_model.dart';
import '../../data/repositories/patient_repository.dart';

// States
abstract class PatientState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PatientInitial extends PatientState {}

class PatientLoading extends PatientState {}

class PatientLoaded extends PatientState {
  final List<PatientModel> patients;

  PatientLoaded(this.patients);

  @override
  List<Object?> get props => [patients];
}

class PatientActionLoading extends PatientState {}

class PatientActionSuccess extends PatientState {
  final String message;

  PatientActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class PatientError extends PatientState {
  final String message;

  PatientError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class PatientCubit extends Cubit<PatientState> {
  final PatientRepository _repository;
  StreamSubscription? _patientsSubscription;
  String? _currentClinicId;

  PatientCubit(this._repository) : super(PatientInitial());

  // تحميل مرضى العيادة
  void loadPatients(String clinicId) {
    _currentClinicId = clinicId;
    emit(PatientLoading());
    _patientsSubscription?.cancel();
    _patientsSubscription = _repository
        .getPatientsByClinic(clinicId)
        .listen(
          (patients) => emit(PatientLoaded(patients)),
          onError: (e) =>
              emit(PatientError('فشل في تحميل المرضى: ${e.toString()}')),
        );
  }

  // إضافة مريض جديد
  Future<void> addPatient(PatientModel patient) async {
    try {
      emit(PatientActionLoading());
      await _repository.addPatient(patient);
      emit(PatientActionSuccess('تم إضافة المريض بنجاح'));
    } catch (e) {
      emit(PatientError('فشل في إضافة المريض: ${e.toString()}'));
    }
  }

  // تحديث بيانات مريض
  Future<void> updatePatient(
    String patientId,
    Map<String, dynamic> updates,
  ) async {
    try {
      emit(PatientActionLoading());
      await _repository.updatePatient(patientId, updates);
      emit(PatientActionSuccess('تم تحديث بيانات المريض بنجاح'));
    } catch (e) {
      emit(PatientError('فشل في تحديث بيانات المريض: ${e.toString()}'));
    }
  }

  // حذف مريض
  Future<void> deletePatient(String patientId) async {
    try {
      emit(PatientActionLoading());
      await _repository.deletePatient(patientId);
      emit(PatientActionSuccess('تم حذف المريض بنجاح'));
    } catch (e) {
      emit(PatientError('فشل في حذف المريض: ${e.toString()}'));
    }
  }

  // البحث عن مرضى
  void searchPatients(String query) {
    if (_currentClinicId == null) return;

    if (query.isEmpty) {
      loadPatients(_currentClinicId!);
      return;
    }

    emit(PatientLoading());
    _patientsSubscription?.cancel();
    _patientsSubscription = _repository
        .searchPatients(_currentClinicId!, query)
        .listen(
          (patients) => emit(PatientLoaded(patients)),
          onError: (e) => emit(PatientError('فشل في البحث: ${e.toString()}')),
        );
  }

  @override
  Future<void> close() {
    _patientsSubscription?.cancel();
    return super.close();
  }
}
