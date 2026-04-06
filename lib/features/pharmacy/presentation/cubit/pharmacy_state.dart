import '../../data/models/pharmacy_model.dart';
import '../../data/models/pharmacy_offer_model.dart';

abstract class PharmacyState {}

class PharmacyInitial extends PharmacyState {}

class PharmacyLoading extends PharmacyState {}

class PharmacyLoaded extends PharmacyState {
  final List<PharmacyModel> pharmacies;
  final List<PharmacyOfferModel> offers;

  PharmacyLoaded({required this.pharmacies, required this.offers});
}

class PharmacyError extends PharmacyState {
  final String message;

  PharmacyError(this.message);
}

class PharmacyDetailsLoading extends PharmacyState {}

class PharmacyDetailsLoaded extends PharmacyState {
  final PharmacyModel pharmacy;
  final List<PharmacyOfferModel> offers;

  PharmacyDetailsLoaded({required this.pharmacy, required this.offers});
}

class PharmacySearchLoading extends PharmacyState {}

class PharmacySearchLoaded extends PharmacyState {
  final List<PharmacyModel> pharmacies;

  PharmacySearchLoaded(this.pharmacies);
}
