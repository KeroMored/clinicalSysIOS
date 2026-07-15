import '../../data/models/medical_supply_model.dart';
import '../../data/models/medical_supply_offer_model.dart';

abstract class MedicalSupplyState {}

class MedicalSupplyInitial extends MedicalSupplyState {}

class MedicalSupplyLoading extends MedicalSupplyState {}

class MedicalSupplyLoaded extends MedicalSupplyState {
  final List<MedicalSupplyModel> medicalSupplies;
  final List<MedicalSupplyOfferModel> offers;

  MedicalSupplyLoaded({required this.medicalSupplies, required this.offers});
}

class MedicalSupplyError extends MedicalSupplyState {
  final String message;

  MedicalSupplyError(this.message);
}

class MedicalSupplyDetailsLoading extends MedicalSupplyState {}

class MedicalSupplyDetailsLoaded extends MedicalSupplyState {
  final MedicalSupplyModel medicalSupply;
  final List<MedicalSupplyOfferModel> offers;

  MedicalSupplyDetailsLoaded({required this.medicalSupply, required this.offers});
}

class MedicalSupplySearchLoading extends MedicalSupplyState {}

class MedicalSupplySearchLoaded extends MedicalSupplyState {
  final List<MedicalSupplyModel> medicalSupplies;

  MedicalSupplySearchLoaded(this.medicalSupplies);
}
