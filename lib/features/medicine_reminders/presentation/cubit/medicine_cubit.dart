import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/medicine_model.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../services/medicine_notification_service.dart';
import 'medicine_state.dart';

class MedicineCubit extends Cubit<MedicineState> {
  final MedicineRepository _repository;
  StreamSubscription? _medicinesSubscription;

  MedicineCubit(this._repository) : super(MedicineInitial());

  void _safeEmit(MedicineState nextState) {
    if (!isClosed) emit(nextState);
  }

  // Load all medicines for current user
  void loadUserMedicines(String userId) {
    if (isClosed) return;
    _safeEmit(MedicineLoading());

    _medicinesSubscription?.cancel();
    _medicinesSubscription = _repository
        .getUserMedicines(userId)
        .listen(
          (medicines) {
            _safeEmit(MedicinesLoaded(medicines));
          },
          onError: (error) {
            _safeEmit(
              MedicineError('فشل في تحميل الأدوية: ${error.toString()}'),
            );
          },
        );
  }

  // Add new medicine
  Future<void> addMedicine(
    MedicineModel medicine, {
    File? imageFile,
    void Function(double progress)? onUploadProgress,
  }) async {
    try {
      if (isClosed) return;
      final currentState = state;
      _safeEmit(MedicineLoading());

      final medicineId = await _repository.addMedicine(
        medicine,
        imageFile: imageFile,
        onUploadProgress: onUploadProgress,
      );

      // Fetch the saved medicine to ensure notification has uploaded image URL.
      final savedMedicine =
          await _repository.getMedicineById(medicineId) ??
          medicine.copyWith(id: medicineId);

      String successMessage = 'تم إضافة الدواء بنجاح';
      try {
        // await MedicineNotificationService.scheduleMedicineNotifications(
        //   savedMedicine,
        // );
      } catch (e) {
        debugPrint('addMedicine notification schedule error: $e');
        successMessage =
            'تم إضافة الدواء بنجاح، لكن تعذر ضبط المنبه الآن. جرّب تفعيل الدواء مرة أخرى.';
      }

      _safeEmit(MedicineAdded(successMessage));

      // Reload medicines
      if (!isClosed && currentState is MedicinesLoaded) {
        loadUserMedicines(medicine.userId);
      }
    } catch (e) {
      _safeEmit(MedicineError('فشل في إضافة الدواء: ${e.toString()}'));
    }
  }

  // Update existing medicine
  Future<void> updateMedicine(
    String id,
    MedicineModel medicine, {
    File? newImageFile,
  }) async {
    try {
      if (isClosed) return;
      _safeEmit(MedicineLoading());

      await _repository.updateMedicine(
        id,
        medicine,
        newImageFile: newImageFile,
      );

      // Re-fetch after update so notification uses latest data (including image URL).
      final updatedMedicine =
          await _repository.getMedicineById(id) ?? medicine.copyWith(id: id);

      String successMessage = 'تم تحديث الدواء بنجاح';
      try {
        // await MedicineNotificationService.updateMedicineNotifications(
        //   updatedMedicine,
        // );
      } catch (e) {
        debugPrint('updateMedicine notification update error: $e');
        successMessage =
            'تم تحديث الدواء بنجاح، لكن تعذر تحديث المنبه الآن. جرّب التفعيل مرة أخرى.';
      }

      _safeEmit(MedicineUpdated(successMessage));

      // Reload medicines
      if (!isClosed) {
        loadUserMedicines(medicine.userId);
      }
    } catch (e) {
      _safeEmit(MedicineError('فشل في تحديث الدواء: ${e.toString()}'));
    }
  }

  // Delete medicine
  Future<void> deleteMedicine(String id, String userId) async {
    try {
      if (isClosed) return;
      await _repository.deleteMedicine(id);

      // Do not fail deletion if notification cancellation throws.
      try {
     //   await MedicineNotificationService.cancelMedicineNotifications(id);
      } catch (e) {
        debugPrint('deleteMedicine notification cancel error: $e');
      }

      try {
      //  await MedicineNotificationService.removeMedicineLocalAssets(id);
      } catch (e) {
        debugPrint('deleteMedicine local assets cleanup error: $e');
      }

      _safeEmit(MedicineDeleted('تم حذف الدواء بنجاح'));

      // Reload medicines
      if (!isClosed) {
        loadUserMedicines(userId);
      }
    } catch (e) {
      _safeEmit(MedicineError('فشل في حذف الدواء: ${e.toString()}'));
    }
  }

  // Toggle medicine active status
  Future<void> toggleMedicineStatus(
    String id,
    bool isActive,
    String userId,
  ) async {
    try {
      if (isClosed) return;
      await _repository.toggleMedicineStatus(id, isActive);

      // Get the medicine to update notifications
      final medicine = await _repository.getMedicineById(id);
      if (medicine != null) {
        try {
          // await MedicineNotificationService.updateMedicineNotifications(
          //   medicine.copyWith(isActive: isActive),
          // );
        } catch (e) {
          debugPrint('toggleMedicineStatus notification update error: $e');
          _safeEmit(
            MedicineError('تم حفظ التغيير، لكن تعذر تحديث المنبه الآن.'),
          );
        }
      }

      // Reload medicines
      if (!isClosed) {
        loadUserMedicines(userId);
      }
    } catch (e) {
      _safeEmit(MedicineError('فشل في تغيير حالة الدواء: ${e.toString()}'));
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
