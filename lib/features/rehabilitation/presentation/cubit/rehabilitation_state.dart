import 'package:mallawicure/features/rehabilitation/data/models/rehabilitation_center_model.dart';

abstract class RehabilitationState {}

class RehabilitationInitial extends RehabilitationState {}

class RehabilitationLoading extends RehabilitationState {}

class RehabilitationLoaded extends RehabilitationState {
  final List<RehabilitationCenterModel> centers;
  RehabilitationLoaded(this.centers);
}

class RehabilitationDetailLoaded extends RehabilitationState {
  final RehabilitationCenterModel center;
  RehabilitationDetailLoaded(this.center);
}

class RehabilitationAdded extends RehabilitationState {
  final String message;
  RehabilitationAdded(this.message);
}

class RehabilitationUpdated extends RehabilitationState {
  final String message;
  RehabilitationUpdated(this.message);
}

class RehabilitationDeleted extends RehabilitationState {
  final String message;
  RehabilitationDeleted(this.message);
}

class RehabilitationApproved extends RehabilitationState {
  final String message;
  RehabilitationApproved(this.message);
}

class RehabilitationRejected extends RehabilitationState {
  final String message;
  RehabilitationRejected(this.message);
}

class RehabilitationError extends RehabilitationState {
  final String message;
  RehabilitationError(this.message);
}
