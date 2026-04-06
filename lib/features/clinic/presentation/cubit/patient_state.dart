import 'package:equatable/equatable.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/medical_visit_model.dart';

abstract class PatientState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PatientInitial extends PatientState {}

class PatientLoading extends PatientState {}

class PatientActionLoading extends PatientState {}

class PatientsLoaded extends PatientState {
  final List<PatientModel> patients;
  final bool hasMore;
  final bool isLoadingMore;

  PatientsLoaded(
    this.patients, {
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  PatientsLoaded copyWith({
    List<PatientModel>? patients,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PatientsLoaded(
      patients ?? this.patients,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [patients, hasMore, isLoadingMore];
}

class PatientDetailsLoaded extends PatientState {
  final PatientModel patient;
  final List<MedicalVisitModel> visits;
  final int visitsCount;

  PatientDetailsLoaded({
    required this.patient,
    required this.visits,
    required this.visitsCount,
  });

  @override
  List<Object?> get props => [patient, visits, visitsCount];
}

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
