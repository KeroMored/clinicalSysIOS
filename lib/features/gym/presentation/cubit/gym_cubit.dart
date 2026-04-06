import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/gym_model.dart';
import '../../data/repositories/gym_repository.dart';
import 'gym_state.dart';

class GymCubit extends Cubit<GymState> {
  final GymRepository _repository;
  StreamSubscription? _gymsSubscription;

  GymCubit(this._repository) : super(GymInitial());

  // Load all approved gyms
  void loadApprovedGyms() {
    emit(GymLoading());
    _gymsSubscription?.cancel();
    _gymsSubscription = _repository.getApprovedGyms().listen(
      (gyms) {
        emit(GymLoaded(gyms));
      },
      onError: (error) {
        emit(GymError('فشل في تحميل الصالات الرياضية: ${error.toString()}'));
      },
    );
  }

  // Load pending gyms for admin
  void loadPendingGyms() {
    emit(GymLoading());
    _gymsSubscription?.cancel();
    _gymsSubscription = _repository.getPendingGyms().listen(
      (gyms) {
        emit(GymPendingLoaded(gyms));
      },
      onError: (error) {
        emit(GymError('فشل في تحميل الصالات المعلقة: ${error.toString()}'));
      },
    );
  }

  // Load gym details
  Future<void> loadGymDetails(String id) async {
    try {
      emit(GymLoading());
      final gym = await _repository.getGymById(id);
      if (gym != null) {
        emit(GymDetailsLoaded(gym));
      } else {
        emit(GymError('الصالة الرياضية غير موجودة'));
      }
    } catch (e) {
      emit(GymError('فشل في تحميل تفاصيل الصالة: ${e.toString()}'));
    }
  }

  // Search gyms
  void searchGyms(String query) {
    emit(GymLoading());
    _gymsSubscription?.cancel();
    _gymsSubscription = _repository
        .searchGyms(query)
        .listen(
          (gyms) {
            emit(GymSearchLoaded(gyms));
          },
          onError: (error) {
            emit(GymError('فشل في البحث: ${error.toString()}'));
          },
        );
  }

  // Filter by gender
  void filterByGender(bool male, bool female) {
    emit(GymLoading());
    _gymsSubscription?.cancel();
    _gymsSubscription = _repository
        .filterByGender(male, female)
        .listen(
          (gyms) {
            emit(GymFilteredByGender(gyms));
          },
          onError: (error) {
            emit(GymError('فشل في التصفية: ${error.toString()}'));
          },
        );
  }

  // Alias for backward compatibility
  void filterByType(bool male, bool female) => filterByGender(male, female);

  // Filter by governorate
  void filterByGovernorate(String governorate) {
    emit(GymLoading());
    _gymsSubscription?.cancel();
    _gymsSubscription = _repository
        .filterByGovernorate(governorate)
        .listen(
          (gyms) {
            emit(GymFilteredByGovernorate(gyms));
          },
          onError: (error) {
            emit(GymError('فشل في التصفية: ${error.toString()}'));
          },
        );
  }

  // Add new gym
  Future<void> addGym(GymModel gym) async {
    try {
      emit(GymLoading());
      final gymId = await _repository.addGym(gym);
      emit(GymAdded(gymId));
    } catch (e) {
      emit(GymError('فشل في إضافة الصالة: ${e.toString()}'));
    }
  }

  // Approve gym
  Future<void> approveGym(String id) async {
    try {
      emit(GymLoading());
      await _repository.approveGym(id);
      emit(GymApproved());
      loadPendingGyms(); // Reload pending list
    } catch (e) {
      emit(GymError('فشل في الموافقة على الصالة: ${e.toString()}'));
    }
  }

  // Delete gym
  Future<void> deleteGym(String id) async {
    try {
      emit(GymLoading());
      await _repository.deleteGym(id);
      emit(GymDeleted());
      loadPendingGyms(); // Reload pending list
    } catch (e) {
      emit(GymError('فشل في حذف الصالة: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _gymsSubscription?.cancel();
    return super.close();
  }
}
