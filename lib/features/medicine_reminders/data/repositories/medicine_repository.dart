import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/medicine_model.dart';

class MedicineRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection reference
  CollectionReference get _medicinesCollection => _firestore.collection('medicine_reminders');

  // Get all medicines for a user
  Stream<List<MedicineModel>> getUserMedicines(String userId) {
    return _medicinesCollection
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true) // عرض الأدوية النشطة فقط
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MedicineModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get single medicine by ID
  Future<MedicineModel?> getMedicineById(String id) async {
    try {
      final doc = await _medicinesCollection.doc(id).get();
      if (doc.exists) {
        return MedicineModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('فشل في تحميل بيانات الدواء: $e');
    }
  }

  // Add new medicine
  Future<String> addMedicine(MedicineModel medicine, {File? imageFile}) async {
    try {
      String? imageUrl;

      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile, medicine.userId);
      }

      // Create medicine with image URL
      final medicineWithImage = medicine.copyWith(imageUrl: imageUrl);
      
      final docRef = await _medicinesCollection.add(medicineWithImage.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('فشل في إضافة الدواء: $e');
    }
  }

  // Update medicine
  Future<void> updateMedicine(String id, MedicineModel medicine, {File? newImageFile}) async {
    try {
      String? imageUrl = medicine.imageUrl;

      // Upload new image if provided
      if (newImageFile != null) {
        // Delete old image if exists
        if (medicine.imageUrl != null) {
          await _deleteImage(medicine.imageUrl!);
        }
        imageUrl = await _uploadImage(newImageFile, medicine.userId);
      }

      final updatedMedicine = medicine.copyWith(imageUrl: imageUrl);
      await _medicinesCollection.doc(id).update(updatedMedicine.toMap());
    } catch (e) {
      throw Exception('فشل في تحديث الدواء: $e');
    }
  }

  // Delete medicine (soft delete by setting isActive to false)
  Future<void> deleteMedicine(String id) async {
    try {
      await _medicinesCollection.doc(id).update({'isActive': false});
    } catch (e) {
      throw Exception('فشل في حذف الدواء: $e');
    }
  }

  // Permanently delete medicine
  Future<void> permanentlyDeleteMedicine(String id, String? imageUrl) async {
    try {
      // Delete image if exists
      if (imageUrl != null) {
        await _deleteImage(imageUrl);
      }

      await _medicinesCollection.doc(id).delete();
    } catch (e) {
      throw Exception('فشل في حذف الدواء نهائياً: $e');
    }
  }

  // Toggle medicine active status
  Future<void> toggleMedicineStatus(String id, bool isActive) async {
    try {
      await _medicinesCollection.doc(id).update({'isActive': isActive});
    } catch (e) {
      throw Exception('فشل في تغيير حالة الدواء: $e');
    }
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImage(File imageFile, String userId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('medicine_images/$userId/$fileName');
      
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('فشل في رفع الصورة: $e');
    }
  }

  // Delete image from Firebase Storage
  Future<void> _deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Ignore errors if image doesn't exist
      print('Error deleting image: $e');
    }
  }

  // Get medicines count for user
  Future<int> getUserMedicinesCount(String userId) async {
    try {
      final snapshot = await _medicinesCollection
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Get active medicines that should remind today
  Future<List<MedicineModel>> getTodayReminders(String userId) async {
    try {
      final snapshot = await _medicinesCollection
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      final medicines = snapshot.docs
          .map((doc) => MedicineModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Filter medicines that have reminders today
      final now = DateTime.now();
      return medicines.where((medicine) {
        switch (medicine.repeatType) {
          case RepeatType.daily:
            return true;
          case RepeatType.weekly:
            return medicine.specificDays?.contains(now.weekday) ?? false;
          case RepeatType.monthly:
            return medicine.monthlyDay == now.day;
          case RepeatType.specificDays:
            return medicine.specificDays?.contains(now.weekday) ?? false;
        }
      }).toList();
    } catch (e) {
      throw Exception('فشل في تحميل تذكيرات اليوم: $e');
    }
  }
}
