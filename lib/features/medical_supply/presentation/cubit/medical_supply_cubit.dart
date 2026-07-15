import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/medical_supply_repository.dart';
import 'medical_supply_state.dart';

class MedicalSupplyCubit extends Cubit<MedicalSupplyState> {
  final MedicalSupplyRepository repository;

  MedicalSupplyCubit(this.repository) : super(MedicalSupplyInitial());

  // Load all medical supplies and offers for homepage
  Future<void> loadMedicalSuppliesAndOffers() async {
    try {
      emit(MedicalSupplyLoading());
      final medicalSupplies = await repository.getAllMedicalSupplies();
      final offers = await repository.getAllOffers();
      emit(MedicalSupplyLoaded(medicalSupplies: medicalSupplies, offers: offers));
    } catch (e) {
      emit(MedicalSupplyError(e.toString()));
    }
  }

  // Load medical supply details with its offers
  Future<void> loadMedicalSupplyDetails(String medicalSupplyId) async {
    try {
      emit(MedicalSupplyDetailsLoading());
      final medicalSupply = await repository.getMedicalSupplyById(medicalSupplyId);
      final offers = await repository.getOffersByMedicalSupplyId(medicalSupplyId);
      emit(MedicalSupplyDetailsLoaded(medicalSupply: medicalSupply, offers: offers));
    } catch (e) {
      emit(MedicalSupplyError(e.toString()));
    }
  }

  // Search medical supplies
  Future<void> searchMedicalSupplies(String query) async {
    try {
      emit(MedicalSupplySearchLoading());
      final medicalSupplies = await repository.searchMedicalSupplies(query);
      emit(MedicalSupplySearchLoaded(medicalSupplies));
    } catch (e) {
      emit(MedicalSupplyError(e.toString()));
    }
  }

  // Reload data
  Future<void> refresh() async {
    await loadMedicalSuppliesAndOffers();
  }
}
