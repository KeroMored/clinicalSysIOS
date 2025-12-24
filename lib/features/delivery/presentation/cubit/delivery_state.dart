import 'package:equatable/equatable.dart';
import '../../data/models/delivery_model.dart';

abstract class DeliveryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DeliveryInitial extends DeliveryState {}

class DeliveryLoading extends DeliveryState {}

class DeliveryLoaded extends DeliveryState {
  final List<DeliveryModel> deliveries;

  DeliveryLoaded(this.deliveries);

  @override
  List<Object?> get props => [deliveries];
}

class DeliveryDetailLoaded extends DeliveryState {
  final DeliveryModel delivery;

  DeliveryDetailLoaded(this.delivery);

  @override
  List<Object?> get props => [delivery];
}

class DeliveryAdded extends DeliveryState {
  final String message;

  DeliveryAdded(this.message);

  @override
  List<Object?> get props => [message];
}

class DeliveryUpdated extends DeliveryState {
  final String message;

  DeliveryUpdated(this.message);

  @override
  List<Object?> get props => [message];
}

class DeliveryApproved extends DeliveryState {
  final String message;

  DeliveryApproved(this.message);

  @override
  List<Object?> get props => [message];
}

class DeliveryRejected extends DeliveryState {
  final String message;

  DeliveryRejected(this.message);

  @override
  List<Object?> get props => [message];
}

class DeliveryDeleted extends DeliveryState {
  final String message;

  DeliveryDeleted(this.message);

  @override
  List<Object?> get props => [message];
}

class DeliveryError extends DeliveryState {
  final String message;

  DeliveryError(this.message);

  @override
  List<Object?> get props => [message];
}
