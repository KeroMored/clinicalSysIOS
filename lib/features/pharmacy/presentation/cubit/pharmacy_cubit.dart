import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/pharmacy_repository.dart';
import 'pharmacy_state.dart';

class PharmacyCubit extends Cubit<PharmacyState> {
  final PharmacyRepository repository;

  PharmacyCubit(this.repository) : super(PharmacyInitial());

  // Load all pharmacies and offers for homepage
  Future<void> loadPharmaciesAndOffers() async {
    try {
      emit(PharmacyLoading());
      final pharmacies = await repository.getAllPharmacies();
      final offers = await repository.getAllOffers();
      emit(PharmacyLoaded(pharmacies: pharmacies, offers: offers));
    } catch (e) {
      emit(PharmacyError(e.toString()));
    }
  }

  // Load pharmacy details with its offers
  Future<void> loadPharmacyDetails(String pharmacyId) async {
    try {
      emit(PharmacyDetailsLoading());
      final pharmacy = await repository.getPharmacyById(pharmacyId);
      final offers = await repository.getOffersByPharmacyId(pharmacyId);
      emit(PharmacyDetailsLoaded(pharmacy: pharmacy, offers: offers));
    } catch (e) {
      emit(PharmacyError(e.toString()));
    }
  }

  // Search pharmacies
  Future<void> searchPharmacies(String query) async {
    try {
      emit(PharmacySearchLoading());
      final pharmacies = await repository.searchPharmacies(query);
      emit(PharmacySearchLoaded(pharmacies));
    } catch (e) {
      emit(PharmacyError(e.toString()));
    }
  }

  // Reload data
  Future<void> refresh() async {
    await loadPharmaciesAndOffers();
  }
}
