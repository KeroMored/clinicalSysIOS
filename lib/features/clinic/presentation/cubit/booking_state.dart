abstract class BookingState {}

class BookingInitial extends BookingState {}

class BookingDeleting extends BookingState {}

class BookingDeleted extends BookingState {}

class BookingUpdating extends BookingState {}

class BookingUpdated extends BookingState {}

class BookingError extends BookingState {
  final String message;

  BookingError(this.message);
}
