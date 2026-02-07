import 'package:equatable/equatable.dart';
import '../../data/models/medicine_model.dart';

abstract class MedicineState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MedicineInitial extends MedicineState {}

class MedicineLoading extends MedicineState {}

class MedicinesLoaded extends MedicineState {
  final List<MedicineModel> medicines;

  MedicinesLoaded(this.medicines);

  @override
  List<Object?> get props => [medicines];
}

class MedicineAdded extends MedicineState {
  final String message;

  MedicineAdded(this.message);

  @override
  List<Object?> get props => [message];
}

class MedicineUpdated extends MedicineState {
  final String message;

  MedicineUpdated(this.message);

  @override
  List<Object?> get props => [message];
}

class MedicineDeleted extends MedicineState {
  final String message;

  MedicineDeleted(this.message);

  @override
  List<Object?> get props => [message];
}

class MedicineError extends MedicineState {
  final String message;

  MedicineError(this.message);

  @override
  List<Object?> get props => [message];
}
