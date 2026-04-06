import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/nurse_model.dart';
import 'nurse_state.dart';

class NurseCubit extends Cubit<NurseState> {
  final FirebaseFirestore _firestore;

  NurseCubit({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      super(NurseInitial());

  // Load all approved nurses
  Future<void> loadApprovedNurses() async {
    try {
      emit(NurseLoading());

      final snapshot = await _firestore
          .collection('nurses')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final nurses = snapshot.docs
          .map((doc) => NurseModel.fromMap(doc.data()))
          .toList();

      emit(NurseLoaded(nurses));
    } catch (e) {
      emit(NurseError('فشل في تحميل الممرضين: $e'));
    }
  }

  // Search nurses by name using Firestore queries
  Future<void> searchNurses(String query) async {
    try {
      emit(NurseLoading());

      final lowerQuery = query.toLowerCase();
      final nursesMap = <String, NurseModel>{};

      // Search by name
      final nameSnapshot = await _firestore
          .collection('nurses')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('nurseName', isGreaterThanOrEqualTo: lowerQuery)
          .where('nurseName', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
          .get();

      for (final doc in nameSnapshot.docs) {
        final nurse = NurseModel.fromMap(doc.data());
        nursesMap[nurse.id] = nurse;
      }

      // Search by specialization
      final specSnapshot = await _firestore
          .collection('nurses')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('specialization', isGreaterThanOrEqualTo: lowerQuery)
          .where('specialization', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
          .get();

      for (final doc in specSnapshot.docs) {
        final nurse = NurseModel.fromMap(doc.data());
        nursesMap[nurse.id] = nurse;
      }

      // Search by governorate
      final govSnapshot = await _firestore
          .collection('nurses')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('governorate', isGreaterThanOrEqualTo: lowerQuery)
          .where('governorate', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
          .get();

      for (final doc in govSnapshot.docs) {
        final nurse = NurseModel.fromMap(doc.data());
        nursesMap[nurse.id] = nurse;
      }

      emit(NurseSearchLoaded(nursesMap.values.toList()));
    } catch (e) {
      emit(NurseError('فشل في البحث: $e'));
    }
  }

  // Filter by governorate
  Future<void> filterByGovernorate(String governorate) async {
    try {
      emit(NurseLoading());

      final snapshot = await _firestore
          .collection('nurses')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('governorate', isEqualTo: governorate)
          .get();

      final nurses = snapshot.docs
          .map((doc) => NurseModel.fromMap(doc.data()))
          .toList();

      emit(NurseFilteredByGovernorate(nurses));
    } catch (e) {
      emit(NurseError('فشل في التصفية: $e'));
    }
  }

  // Filter by specialization
  Future<void> filterBySpecialization(String specialization) async {
    try {
      emit(NurseLoading());

      final snapshot = await _firestore
          .collection('nurses')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('specialization', isEqualTo: specialization)
          .get();

      final nurses = snapshot.docs
          .map((doc) => NurseModel.fromMap(doc.data()))
          .toList();

      emit(NurseFilteredBySpecialization(nurses));
    } catch (e) {
      emit(NurseError('فشل في التصفية: $e'));
    }
  }

  // Filter by gender
  Future<void> filterByGender(String gender) async {
    try {
      emit(NurseLoading());

      final snapshot = await _firestore
          .collection('nurses')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('gender', isEqualTo: gender)
          .get();

      final nurses = snapshot.docs
          .map((doc) => NurseModel.fromMap(doc.data()))
          .toList();

      emit(NurseFilteredByGender(nurses));
    } catch (e) {
      emit(NurseError('فشل في التصفية: $e'));
    }
  }

  // Load nurses available 24/7
  Future<void> loadAvailable24HoursNurses() async {
    try {
      emit(NurseLoading());

      final snapshot = await _firestore
          .collection('nurses')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('available24Hours', isEqualTo: true)
          .get();

      final nurses = snapshot.docs
          .map((doc) => NurseModel.fromMap(doc.data()))
          .toList();

      emit(NurseAvailable24Hours(nurses));
    } catch (e) {
      emit(NurseError('فشل في تحميل الممرضين المتاحين: $e'));
    }
  }

  // Load nurses available now
  Future<void> loadAvailableNowNurses() async {
    try {
      emit(NurseLoading());

      final snapshot = await _firestore
          .collection('nurses')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('availableNow', isEqualTo: true)
          .get();

      final nurses = snapshot.docs
          .map((doc) => NurseModel.fromMap(doc.data()))
          .toList();

      emit(NurseAvailableNow(nurses));
    } catch (e) {
      emit(NurseError('فشل في تحميل الممرضين المتاحين: $e'));
    }
  }

  // Add new nurse
  Future<void> addNurse(NurseModel nurse) async {
    try {
      await _firestore.collection('nurses').doc(nurse.id).set(nurse.toMap());
    } catch (e) {
      throw Exception('فشل في إضافة الممرض: $e');
    }
  }

  // Update nurse
  Future<void> updateNurse(NurseModel nurse) async {
    try {
      await _firestore.collection('nurses').doc(nurse.id).update(nurse.toMap());
    } catch (e) {
      throw Exception('فشل في تحديث البيانات: $e');
    }
  }

  // Delete nurse
  Future<void> deleteNurse(String nurseId) async {
    try {
      await _firestore.collection('nurses').doc(nurseId).delete();
    } catch (e) {
      throw Exception('فشل في حذف الممرض: $e');
    }
  }

  // Approve nurse
  Future<void> approveNurse(String nurseId) async {
    try {
      await _firestore.collection('nurses').doc(nurseId).update({
        'isApproved': true,
        'status': 'approved',
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('فشل في الموافقة: $e');
    }
  }

  // Reject nurse
  Future<void> rejectNurse(String nurseId, String reason) async {
    try {
      await _firestore.collection('nurses').doc(nurseId).update({
        'isApproved': false,
        'status': 'rejected',
        'notes': reason,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('فشل في الرفض: $e');
    }
  }
}
