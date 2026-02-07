import 'package:equatable/equatable.dart';
import '../../data/models/emergency_number_model.dart';

abstract class EmergencyState extends Equatable {
  const EmergencyState();

  @override
  List<Object?> get props => [];
}

class EmergencyInitial extends EmergencyState {}

class EmergencyLoading extends EmergencyState {}

class EmergencyLoaded extends EmergencyState {
  final List<EmergencyNumberModel> numbers;

  const EmergencyLoaded(this.numbers);

  @override
  List<Object?> get props => [numbers];
}

class EmergencyError extends EmergencyState {
  final String message;

  const EmergencyError(this.message);

  @override
  List<Object?> get props => [message];
}
