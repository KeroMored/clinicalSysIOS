import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/medicine_offer_model.dart';
import '../../data/repositories/medicine_offer_repository.dart';

// States
abstract class MedicineOfferState {}

class MedicineOfferInitial extends MedicineOfferState {}

class MedicineOfferLoading extends MedicineOfferState {}

class MedicineOfferLoaded extends MedicineOfferState {
  final List<MedicineOfferModel> offers;
  MedicineOfferLoaded(this.offers);
}

class MedicineOfferError extends MedicineOfferState {
  final String message;
  MedicineOfferError(this.message);
}

class MedicineOfferAdded extends MedicineOfferState {
  final String message;
  MedicineOfferAdded(this.message);
}

class MedicineOfferUpdated extends MedicineOfferState {
  final String message;
  MedicineOfferUpdated(this.message);
}

class MedicineOfferDeleted extends MedicineOfferState {
  final String message;
  MedicineOfferDeleted(this.message);
}

// Cubit
class MedicineOfferCubit extends Cubit<MedicineOfferState> {
  final MedicineOfferRepository _repository;

  MedicineOfferCubit(this._repository) : super(MedicineOfferInitial());

  // جلب كل العروض النشطة
  Future<void> loadAllActiveOffers() async {
    try {
      emit(MedicineOfferLoading());
      final offers = await _repository.getAllActiveOffers();
      emit(MedicineOfferLoaded(offers));
    } catch (e) {
      emit(MedicineOfferError(e.toString()));
    }
  }

  // جلب عروض صيدلية معينة
  Future<void> loadOffersByPharmacy(String pharmacyId) async {
    try {
      emit(MedicineOfferLoading());
      final offers = await _repository.getOffersByPharmacy(pharmacyId);
      emit(MedicineOfferLoaded(offers));
    } catch (e) {
      emit(MedicineOfferError(e.toString()));
    }
  }

  // جلب كل عروض الصيدلية (بما فيها الغير نشطة) - للإدارة
  Future<void> loadAllOffersByPharmacy(String pharmacyId) async {
    try {
      emit(MedicineOfferLoading());
      final offers = await _repository.getAllOffersByPharmacy(pharmacyId);
      emit(MedicineOfferLoaded(offers));
    } catch (e) {
      emit(MedicineOfferError(e.toString()));
    }
  }

  // إضافة عرض جديد
  Future<void> addOffer(MedicineOfferModel offer) async {
    try {
      emit(MedicineOfferLoading());
      await _repository.addOffer(offer);
      emit(MedicineOfferAdded('تم إضافة العرض بنجاح'));
    } catch (e) {
      emit(MedicineOfferError(e.toString()));
    }
  }

  // تحديث كمية العرض
  Future<void> updateQuantity(String offerId, int newQuantity) async {
    try {
      await _repository.updateQuantity(offerId, newQuantity);
      if (newQuantity <= 0) {
        emit(MedicineOfferDeleted('تم حذف العرض (الكمية = 0)'));
      } else {
        emit(MedicineOfferUpdated('تم تحديث الكمية بنجاح'));
      }
    } catch (e) {
      emit(MedicineOfferError(e.toString()));
    }
  }

  // تحديث العرض
  Future<void> updateOffer(MedicineOfferModel offer) async {
    try {
      emit(MedicineOfferLoading());
      await _repository.updateOffer(offer);
      emit(MedicineOfferUpdated('تم تحديث العرض بنجاح'));
    } catch (e) {
      emit(MedicineOfferError(e.toString()));
    }
  }

  // حذف العرض
  Future<void> deleteOffer(String offerId) async {
    try {
      await _repository.deleteOffer(offerId);
      emit(MedicineOfferDeleted('تم حذف العرض بنجاح'));
    } catch (e) {
      emit(MedicineOfferError(e.toString()));
    }
  }
}
