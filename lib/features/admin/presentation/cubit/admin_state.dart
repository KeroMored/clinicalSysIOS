import '../../data/models/pharmacy_request_model.dart';
import '../../../laboratory/data/models/laboratory_model.dart';

abstract class AdminState {}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class PharmacyRequestsLoaded extends AdminState {
  final List<PharmacyRequestModel> requests;

  PharmacyRequestsLoaded(this.requests);
}

class ClinicRequestsLoaded extends AdminState {
  final List<Map<String, dynamic>> requests;

  ClinicRequestsLoaded(this.requests);
}

class LaboratoryRequestsLoaded extends AdminState {
  final List<LaboratoryModel> laboratories;

  LaboratoryRequestsLoaded(this.laboratories);
}

class AdminError extends AdminState {
  final String message;

  AdminError(this.message);
}

class RequestDetailsLoading extends AdminState {}

class RequestDetailsLoaded extends AdminState {
  final PharmacyRequestModel request;

  RequestDetailsLoaded(this.request);
}

class RequestApproving extends AdminState {}

class RequestApproved extends AdminState {
  final String message;

  RequestApproved(this.message);
}

class RequestRejecting extends AdminState {}

class RequestRejected extends AdminState {
  final String message;

  RequestRejected(this.message);
}

class RequestSettingToPending extends AdminState {}

class RequestSetToPending extends AdminState {
  final String message;

  RequestSetToPending(this.message);
}

class RequestSubmitting extends AdminState {}

class RequestSubmitted extends AdminState {
  final String message;

  RequestSubmitted(this.message);
}

class PharmacyAddedSuccessfully extends AdminState {
  final String message;

  PharmacyAddedSuccessfully(this.message);
}

class NurseRequestsLoaded extends AdminState {
  final List<Map<String, dynamic>> requests;

  NurseRequestsLoaded(this.requests);
}

class NurseAdded extends AdminState {
  final String message;

  NurseAdded(this.message);
}

class DeliveryAdded extends AdminState {
  final String message;

  DeliveryAdded(this.message);
}

class RehabilitationCenterAdded extends AdminState {
  final String message;

  RehabilitationCenterAdded(this.message);
}
