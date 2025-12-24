import 'package:equatable/equatable.dart';
import '../../data/models/nurse_model.dart';

abstract class NurseState extends Equatable {
  const NurseState();

  @override
  List<Object?> get props => [];
}

class NurseInitial extends NurseState {}

class NurseLoading extends NurseState {}

class NurseLoaded extends NurseState {
  final List<NurseModel> nurses;

  const NurseLoaded(this.nurses);

  @override
  List<Object?> get props => [nurses];
}

class NurseError extends NurseState {
  final String message;

  const NurseError(this.message);

  @override
  List<Object?> get props => [message];
}

class NurseSearchLoaded extends NurseState {
  final List<NurseModel> searchResults;

  const NurseSearchLoaded(this.searchResults);

  @override
  List<Object?> get props => [searchResults];
}

class NurseFilteredByGovernorate extends NurseState {
  final List<NurseModel> nurses;

  const NurseFilteredByGovernorate(this.nurses);

  @override
  List<Object?> get props => [nurses];
}

class NurseFilteredBySpecialization extends NurseState {
  final List<NurseModel> nurses;

  const NurseFilteredBySpecialization(this.nurses);

  @override
  List<Object?> get props => [nurses];
}

class NurseFilteredByGender extends NurseState {
  final List<NurseModel> nurses;

  const NurseFilteredByGender(this.nurses);

  @override
  List<Object?> get props => [nurses];
}

class NurseAvailable24Hours extends NurseState {
  final List<NurseModel> nurses;

  const NurseAvailable24Hours(this.nurses);

  @override
  List<Object?> get props => [nurses];
}

class NurseAvailableNow extends NurseState {
  final List<NurseModel> nurses;

  const NurseAvailableNow(this.nurses);

  @override
  List<Object?> get props => [nurses];
}
