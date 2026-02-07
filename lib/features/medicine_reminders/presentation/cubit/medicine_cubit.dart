import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/medicine_model.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../services/medicine_notification_service.dart';
import 'medicine_state.dart';

class MedicineCubit extends Cubit<MedicineState> {
  final MedicineRepository _repository;
  StreamSubscription? _medicinesSubscription;

  MedicineCubit(this._repository) : super(MedicineInitial());

  // Load all medicines for current user
  void loadUserMedicines(String userId) {
    emit(MedicineLoading());
    
    _medicinesSubscription?.cancel();
    _medicinesSubscription = _repository.getUserMedicines(userId).listen(
      (medicines) {
        emit(MedicinesLoaded(medicines));
      },
      onError: (error) {
        emit(MedicineError('فشل في تحميل الأدوية: ${error.toString()}'));
      },
    );
  }

  // Add new medicine
  Future<void> addMedicine(
    MedicineModel medicine, {
    File? imageFile,
  }) async {
    try {
      final currentState = state;
      emit(MedicineLoading());
      
      final medicineId = await _repository.addMedicine(medicine, imageFile: imageFile);
      
      // Schedule notifications for the new medicine
      final savedMedicine = medicine.copyWith(id: medicineId);
      await MedicineNotificationService.scheduleMedicineNotifications(savedMedicine);
      
      emit(MedicineAdded('تم إضافة الدواء بنجاح'));
      
      // Reload medicines
      if (currentState is MedicinesLoaded) {
        loadUserMedicines(medicine.userId);
      }
    } catch (e) {
      emit(MedicineError('فشل في إضافة الدواء: ${e.toString()}'));
    }
  }

  // Update existing medicine
  Future<void> updateMedicine(
    String id,
    MedicineModel medicine, {
    File? newImageFile,
  }) async {
    try {
      emit(MedicineLoading());
      
      await _repository.updateMedicine(id, medicine, newImageFile: newImageFile);
      
      // Update notifications (cancel old and schedule new if active)
      final updatedMedicine = medicine.copyWith(id: id);
      await MedicineNotificationService.updateMedicineNotifications(updatedMedicine);
      
      emit(MedicineUpdated('تم تحديث الدواء بنجاح'));
      
      // Reload medicines
      loadUserMedicines(medicine.userId);
    } catch (e) {
      emit(MedicineError('فشل في تحديث الدواء: ${e.toString()}'));
    }
  }

  // Delete medicine
  Future<void> deleteMedicine(String id, String userId) async {
    try {
      await _repository.deleteMedicine(id);
      
      // Cancel notifications for this medicine
      await MedicineNotificationService.cancelMedicineNotifications(id);
      
      emit(MedicineDeleted('تم حذف الدواء بنجاح'));
      
      // Reload medicines
      loadUserMedicines(userId);
    } catch (e) {
      emit(MedicineError('فشل في حذف الدواء: ${e.toString()}'));
    }
  }

  // Toggle medicine active status
  Future<void> toggleMedicineStatus(String id, bool isActive, String userId) async {
    try {
      await _repository.toggleMedicineStatus(id, isActive);
      
      // Get the medicine to update notifications
      final medicine = await _repository.getMedicineById(id);
      if (medicine != null) {
        await MedicineNotificationService.updateMedicineNotifications(medicine.copyWith(isActive: isActive));
      }
      
      // Reload medicines
      loadUserMedicines(userId);
    } catch (e) {
      emit(MedicineError('فشل في تغيير حالة الدواء: ${e.toString()}'));
    }
  }

  // Get today's reminders
  Future<List<MedicineModel>> getTodayReminders(String userId) async {
    try {
      return await _repository.getTodayReminders(userId);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> close() {
    _medicinesSubscription?.cancel();
    return super.close();
  }
}
