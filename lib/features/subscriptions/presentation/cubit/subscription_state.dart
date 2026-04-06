import 'package:equatable/equatable.dart';
import '../../data/models/subscription_settings_model.dart';
import '../../data/models/subscribed_place_model.dart';
import '../../data/models/payment_record_model.dart';

abstract class SubscriptionState extends Equatable {
  @override
  List<Object?> get props => [];
}

// Initial state
class SubscriptionInitial extends SubscriptionState {}

// Loading states
class SubscriptionLoading extends SubscriptionState {}

class PlacesLoading extends SubscriptionState {}

class PaymentsLoading extends SubscriptionState {}

class SyncingPlaces extends SubscriptionState {}

// Loaded states
class SubscriptionLoaded extends SubscriptionState {
  final List<SubscribedPlaceModel> places;
  final SubscriptionSettingsModel settings;
  final Map<String, dynamic>? statistics;
  final PlaceType? filterType;
  final String? searchQuery;
  final bool hasMoreData;

  SubscriptionLoaded({
    required this.places,
    required this.settings,
    this.statistics,
    this.filterType,
    this.searchQuery,
    this.hasMoreData = false,
  });

  @override
  List<Object?> get props => [
    places,
    settings,
    statistics,
    filterType,
    searchQuery,
    hasMoreData,
  ];

  SubscriptionLoaded copyWith({
    List<SubscribedPlaceModel>? places,
    SubscriptionSettingsModel? settings,
    Map<String, dynamic>? statistics,
    PlaceType? filterType,
    String? searchQuery,
    bool? hasMoreData,
  }) {
    return SubscriptionLoaded(
      places: places ?? this.places,
      settings: settings ?? this.settings,
      statistics: statistics ?? this.statistics,
      filterType: filterType,
      searchQuery: searchQuery,
      hasMoreData: hasMoreData ?? this.hasMoreData,
    );
  }
}

class PlaceDetailsLoaded extends SubscriptionState {
  final SubscribedPlaceModel place;
  final List<PaymentRecordModel> payments;
  final SubscriptionSettingsModel settings;

  PlaceDetailsLoaded({
    required this.place,
    required this.payments,
    required this.settings,
  });

  @override
  List<Object?> get props => [place, payments, settings];
}

// Success states
class SettingsUpdated extends SubscriptionState {
  final String message;

  SettingsUpdated(this.message);

  @override
  List<Object?> get props => [message];
}

class PaymentRecorded extends SubscriptionState {
  final String message;

  PaymentRecorded(this.message);

  @override
  List<Object?> get props => [message];
}

class NotesUpdated extends SubscriptionState {
  final String message;

  NotesUpdated(this.message);

  @override
  List<Object?> get props => [message];
}

class PlacesSynced extends SubscriptionState {
  final String message;
  final int syncedCount;

  PlacesSynced(this.message, this.syncedCount);

  @override
  List<Object?> get props => [message, syncedCount];
}

class PlaceDeleted extends SubscriptionState {
  final String message;

  PlaceDeleted(this.message);

  @override
  List<Object?> get props => [message];
}

class PaymentDeleted extends SubscriptionState {
  final String message;

  PaymentDeleted(this.message);

  @override
  List<Object?> get props => [message];
}

// Error state
class SubscriptionError extends SubscriptionState {
  final String message;

  SubscriptionError(this.message);

  @override
  List<Object?> get props => [message];
}
