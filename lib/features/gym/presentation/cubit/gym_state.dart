import '../../data/models/gym_model.dart';

abstract class GymState {}

class GymInitial extends GymState {}

class GymLoading extends GymState {}

class GymLoaded extends GymState {
  final List<GymModel> gyms;
  GymLoaded(this.gyms);
}

class GymPendingLoaded extends GymState {
  final List<GymModel> gyms;
  GymPendingLoaded(this.gyms);
}

class GymSearchLoaded extends GymState {
  final List<GymModel> searchResults;
  GymSearchLoaded(this.searchResults);
}

class GymFilteredByGender extends GymState {
  final List<GymModel> gyms;
  GymFilteredByGender(this.gyms);
}

// Alias for backward compatibility
typedef GymFilteredByType = GymFilteredByGender;

class GymFilteredByGovernorate extends GymState {
  final List<GymModel> gyms;
  GymFilteredByGovernorate(this.gyms);
}

class GymDetailsLoaded extends GymState {
  final GymModel gym;
  GymDetailsLoaded(this.gym);
}

class GymAdded extends GymState {
  final String gymId;
  GymAdded(this.gymId);
}

class GymApproved extends GymState {}

class GymDeleted extends GymState {}

class GymError extends GymState {
  final String message;
  GymError(this.message);
}
