import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/medical_visit_model.dart';
import '../../data/repositories/patient_repository.dart';
import 'patient_state.dart';

class PatientCubit extends Cubit<PatientState> {
  final PatientRepository _repository;
  StreamSubscription? _patientsSubscription;
  StreamSubscription? _patientSubscription;
  StreamSubscription? _visitsSubscription;
  StreamSubscription? _visitsCountSubscription;

  PatientCubit(this._repository) : super(PatientInitial());

  void loadClinicPatients(String clinicId) {
    emit(PatientLoading());
    _patientsSubscription?.cancel();
    _patientsSubscription = _repository.getClinicPatients(clinicId).listen(
      (patients) => emit(PatientsLoaded(patients)),
      onError: (e) => emit(PatientError('فشل في تحميل المرضى: ${e.toString()}')),
    );
  }

  void loadPatientDetails(String patientId) {
    emit(PatientLoading());
    _patientSubscription?.cancel();
    _visitsSubscription?.cancel();
    _visitsCountSubscription?.cancel();

    PatientModel? currentPatient;
    List<MedicalVisitModel>? currentVisits;
    int? currentCount;

    void tryEmit() {
      if (currentPatient != null && currentVisits != null && currentCount != null) {
        emit(PatientDetailsLoaded(
          patient: currentPatient!,
          visits: currentVisits!,
          visitsCount: currentCount!,
        ));
      }
    }

    _patientSubscription = _repository.getPatient(patientId).listen(
      (patient) {
        currentPatient = patient;
        tryEmit();
      },
      onError: (e) => emit(PatientError('فشل في تحميل بيانات المريض: ${e.toString()}')),
    );

    _visitsSubscription = _repository.getPatientVisits(patientId).listen(
      (visits) {
        currentVisits = visits;
        tryEmit();
      },
      onError: (e) => emit(PatientError('فشل في تحميل الكشوفات: ${e.toString()}')),
    );

    _visitsCountSubscription = _repository.getPatientVisitsCount(patientId).listen(
      (count) {
        currentCount = count;
        tryEmit();
      },
    );
  }

  Future<void> addPatient({
    required String clinicId,
    required String name,
    required String phoneNumber,
    String? whatsappNumber,
  }) async {
    try {
      emit(PatientActionLoading());
      final patient = PatientModel(
        id: '',
        name: name,
        phoneNumber: phoneNumber,
        whatsappNumber: whatsappNumber,
        clinicId: clinicId,
        createdAt: DateTime.now(),
      );
      await _repository.addPatient(patient);
      emit(PatientActionSuccess('تم إضافة المريض بنجاح'));
    } catch (e) {
      emit(PatientError('فشل في إضافة المريض: ${e.toString()}'));
    }
  }

  Future<void> updatePatient(PatientModel patient) async {
    try {
      emit(PatientActionLoading());
      await _repository.updatePatient(patient);
      emit(PatientActionSuccess('تم تحديث بيانات المريض بنجاح'));
    } catch (e) {
      emit(PatientError('فشل في تحديث بيانات المريض: ${e.toString()}'));
    }
  }

  Future<void> deletePatient(String patientId) async {
    try {
      emit(PatientActionLoading());
      await _repository.deletePatient(patientId);
      emit(PatientActionSuccess('تم حذف المريض بنجاح'));
    } catch (e) {
      emit(PatientError('فشل في حذف المريض: ${e.toString()}'));
    }
  }

  Future<void> addVisit({
    required String patientId,
    required String clinicId,
    required DateTime visitDate,
    String? diagnosis, // اختياري الآن
    required List<String> medications,
    List<File>? prescriptionImages, // قائمة صور
  }) async {
    try {
      emit(PatientActionLoading());
      
      // رفع جميع الصور بشكل متوازي للسرعة
      List<String> imageUrls = [];
      if (prescriptionImages != null && prescriptionImages.isNotEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final uploadFutures = prescriptionImages.asMap().entries.map((entry) {
          final index = entry.key;
          final image = entry.value;
          return _repository.uploadPrescriptionImage(
            patientId,
            '${timestamp}_$index',
            image,
          );
        });
        
        final results = await Future.wait(uploadFutures);
        imageUrls = results.whereType<String>().toList();
      }

      final visit = MedicalVisitModel(
        id: '',
        patientId: patientId,
        clinicId: clinicId,
        visitDate: visitDate,
        diagnosis: diagnosis,
        medications: medications,
        prescriptionImageUrls: imageUrls,
        createdAt: DateTime.now(),
      );
      await _repository.addVisit(visit);
      emit(PatientActionSuccess('تم إضافة الكشف بنجاح'));
    } catch (e) {
      emit(PatientError('فشل في إضافة الكشف: ${e.toString()}'));
    }
  }

  Future<void> updateVisit(MedicalVisitModel visit, {List<File>? newPrescriptionImages}) async {
    try {
      emit(PatientActionLoading());
      
      List<String> imageUrls = List.from(visit.prescriptionImageUrls);
      
      // رفع الصور الجديدة بشكل متوازي
      if (newPrescriptionImages != null && newPrescriptionImages.isNotEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final uploadFutures = newPrescriptionImages.asMap().entries.map((entry) {
          final index = entry.key;
          final image = entry.value;
          return _repository.uploadPrescriptionImage(
            visit.patientId,
            '${visit.id}_${timestamp}_$index',
            image,
          );
        });
        
        final results = await Future.wait(uploadFutures);
        final newUrls = results.whereType<String>().toList();
        imageUrls.addAll(newUrls);
      }

      final updatedVisit = visit.copyWith(prescriptionImageUrls: imageUrls);
      await _repository.updateVisit(updatedVisit);
      emit(PatientActionSuccess('تم تحديث الكشف بنجاح'));
    } catch (e) {
      emit(PatientError('فشل في تحديث الكشف: ${e.toString()}'));
    }
  }

  Future<void> deleteVisit(String visitId) async {
    try {
      emit(PatientActionLoading());
      await _repository.deleteVisit(visitId);
      emit(PatientActionSuccess('تم حذف الكشف بنجاح'));
    } catch (e) {
      emit(PatientError('فشل في حذف الكشف: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _patientsSubscription?.cancel();
    _patientSubscription?.cancel();
    _visitsSubscription?.cancel();
    _visitsCountSubscription?.cancel();
    return super.close();
  }
}
