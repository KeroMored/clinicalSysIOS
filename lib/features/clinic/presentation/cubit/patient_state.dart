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

  PatientsLoaded(this.patients);

  @override
  List<Object?> get props => [patients];
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
