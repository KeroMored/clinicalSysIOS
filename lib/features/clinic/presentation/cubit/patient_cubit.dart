import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/medical_visit_model.dart';
import '../../data/repositories/patient_repository.dart';
import 'patient_state.dart';

class PatientCubit extends Cubit<PatientState> {
  final PatientRepository _repository;
  StreamSubscription? _patientSubscription;
  StreamSubscription? _visitsSubscription;
  StreamSubscription? _visitsCountSubscription;
  static const int _pageSize = 10;

  String? _currentClinicId;
  DocumentSnapshot? _lastPatientsDocument;
  bool _hasMorePatients = true;
  bool _isLoadingMore = false;
  bool _hasLoadedClinicPatients = false;
  final List<PatientModel> _patients = [];

  PatientCubit(this._repository) : super(PatientInitial());

  bool hasCachedClinicPatients(String clinicId) {
    return _currentClinicId == clinicId && _hasLoadedClinicPatients;
  }

  List<PatientModel> get cachedClinicPatients =>
      List<PatientModel>.from(_patients);

  bool get cachedClinicHasMore => _hasMorePatients;

  Future<void> ensureClinicPatientsLoaded(
    String clinicId, {
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      await loadClinicPatients(clinicId);
      return;
    }

    if (hasCachedClinicPatients(clinicId)) {
      restoreClinicPatientsFromCache(clinicId);
      return;
    }

    await loadClinicPatients(clinicId);
  }

  void restoreClinicPatientsFromCache(String clinicId) {
    if (!hasCachedClinicPatients(clinicId)) {
      return;
    }

    emit(
      PatientsLoaded(
        List<PatientModel>.from(_patients),
        hasMore: _hasMorePatients,
        isLoadingMore: false,
      ),
    );
  }

  Future<void> loadClinicPatients(String clinicId) async {
    _currentClinicId = clinicId;
    _lastPatientsDocument = null;
    _hasMorePatients = true;
    _isLoadingMore = false;
    _patients.clear();

    emit(PatientLoading());

    try {
      final page = await _repository.getClinicPatientsPage(
        clinicId,
        limit: _pageSize,
      );
      _patients
        ..clear()
        ..addAll(page.patients);
      _lastPatientsDocument = page.lastDocument;
      _hasMorePatients = page.hasMore;
      _hasLoadedClinicPatients = true;

      emit(
        PatientsLoaded(
          List<PatientModel>.from(_patients),
          hasMore: _hasMorePatients,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(PatientError('فشل في تحميل المرضى: ${e.toString()}'));
    }
  }

  Future<void> loadMoreClinicPatients() async {
    if (_currentClinicId == null || _isLoadingMore || !_hasMorePatients) {
      return;
    }

    final currentState = state;
    if (currentState is! PatientsLoaded) {
      return;
    }

    _isLoadingMore = true;
    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final page = await _repository.getClinicPatientsPage(
        _currentClinicId!,
        limit: _pageSize,
        lastDocument: _lastPatientsDocument,
      );

      _patients.addAll(page.patients);
      _lastPatientsDocument = page.lastDocument;
      _hasMorePatients = page.hasMore;
      _isLoadingMore = false;

      emit(
        PatientsLoaded(
          List<PatientModel>.from(_patients),
          hasMore: _hasMorePatients,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      _isLoadingMore = false;
      emit(PatientError('فشل في تحميل المزيد من المرضى: ${e.toString()}'));
      emit(currentState.copyWith(isLoadingMore: false));
    }
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
      if (currentPatient != null &&
          currentVisits != null &&
          currentCount != null) {
        emit(
          PatientDetailsLoaded(
            patient: currentPatient!,
            visits: currentVisits!,
            visitsCount: currentCount!,
          ),
        );
      }
    }

    _patientSubscription = _repository.getPatient(patientId).listen(
      (patient) {
        currentPatient = patient;
        tryEmit();
      },
      onError: (e) =>
          emit(PatientError('فشل في تحميل بيانات المريض: ${e.toString()}')),
    );

    _visitsSubscription = _repository.getPatientVisits(patientId).listen(
      (visits) {
        currentVisits = visits;
        tryEmit();
      },
      onError: (e) =>
          emit(PatientError('فشل في تحميل الكشوفات: ${e.toString()}')),
    );

    _visitsCountSubscription = _repository
        .getPatientVisitsCount(patientId)
        .listen((count) {
          currentCount = count;
          tryEmit();
        });
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

  Future<void> updateVisit(
    MedicalVisitModel visit, {
    List<File>? newPrescriptionImages,
  }) async {
    try {
      emit(PatientActionLoading());

      List<String> imageUrls = List.from(visit.prescriptionImageUrls);

      // رفع الصور الجديدة بشكل متوازي
      if (newPrescriptionImages != null && newPrescriptionImages.isNotEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final uploadFutures = newPrescriptionImages.asMap().entries.map((
          entry,
        ) {
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
    _patientSubscription?.cancel();
    _visitsSubscription?.cancel();
    _visitsCountSubscription?.cancel();
    return super.close();
  }
}
