import '../../data/models/radiology_model.dart';

abstract class RadiologyState {}

// Initial State
class RadiologyInitial extends RadiologyState {}

// Loading States
class RadiologyLoading extends RadiologyState {}

class RadiologyActionLoading extends RadiologyState {}

// Success States
class RadiologyLoaded extends RadiologyState {
  final List<RadiologyModel> radiologyCenters;

  RadiologyLoaded(this.radiologyCenters);
}

class RadiologyActionSuccess extends RadiologyState {
  final String message;

  RadiologyActionSuccess(this.message);
}

class RadiologyCenterDetailLoaded extends RadiologyState {
  final RadiologyModel radiologyCenter;

  RadiologyCenterDetailLoaded(this.radiologyCenter);
}

// Error State
class RadiologyError extends RadiologyState {
  final String message;

  RadiologyError(this.message);
}

// Search State
class RadiologySearchLoaded extends RadiologyState {
  final List<RadiologyModel> searchResults;
  final String query;

  RadiologySearchLoaded(this.searchResults, this.query);
}

// Filter States
class RadiologyFilteredByGovernorate extends RadiologyState {
  final List<RadiologyModel> radiologyCenters;
  final String governorate;

  RadiologyFilteredByGovernorate(this.radiologyCenters, this.governorate);
}

class RadiologyFilteredByService extends RadiologyState {
  final List<RadiologyModel> radiologyCenters;
  final String service;

  RadiologyFilteredByService(this.radiologyCenters, this.service);
}

class RadiologyEmergencyLoaded extends RadiologyState {
  final List<RadiologyModel> radiologyCenters;

  RadiologyEmergencyLoaded(this.radiologyCenters);
}

class RadiologyHomeVisitLoaded extends RadiologyState {
  final List<RadiologyModel> radiologyCenters;

  RadiologyHomeVisitLoaded(this.radiologyCenters);
}

// Pending radiology centers for admin
class RadiologyPendingLoaded extends RadiologyState {
  final List<RadiologyModel> pendingCenters;

  RadiologyPendingLoaded(this.pendingCenters);
}
