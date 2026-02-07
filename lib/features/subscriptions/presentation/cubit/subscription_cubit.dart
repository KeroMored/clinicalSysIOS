import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/subscription_settings_model.dart';
import '../../data/models/subscribed_place_model.dart';
import '../../data/models/payment_record_model.dart';
import '../../data/repositories/subscription_repository.dart';
import 'subscription_state.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  final SubscriptionRepository _repository;
  StreamSubscription? _placesSubscription;
  StreamSubscription? _paymentsSubscription;
  
  // Pagination
  static const int _pageSize = 10;
  List<SubscribedPlaceModel> _allPlaces = [];
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  PlaceType? _currentFilterType; // Track current filter

  SubscriptionCubit(this._repository) : super(SubscriptionInitial());

  // ==================== Load Data ====================

  // Load all places with settings and statistics (with pagination)
  Future<void> loadAllPlaces() async {
    emit(SubscriptionLoading());
    try {
      final settings = await _repository.getSettings();
      final statistics = await _repository.getStatistics();

      _allPlaces = [];
      _hasMoreData = true;
      _isLoadingMore = false;
      _currentFilterType = null; // Reset filter

      _placesSubscription?.cancel();
      _placesSubscription = _repository.getAllSubscribedPlacesPaginated(limit: _pageSize).listen(
        (places) {
          _allPlaces = places;
          _hasMoreData = places.length >= _pageSize;
          emit(SubscriptionLoaded(
            places: places,
            settings: settings,
            statistics: statistics,
            hasMoreData: _hasMoreData,
          ));
        },
        onError: (error) {
          emit(SubscriptionError('فشل في تحميل الأماكن: $error'));
        },
      );
    } catch (e) {
      emit(SubscriptionError('فشل في تحميل البيانات: $e'));
    }
  }

  // Load more places (pagination)
  Future<void> loadMorePlaces() async {
    if (_isLoadingMore || !_hasMoreData) return;
    
    final currentState = state;
    if (currentState is! SubscriptionLoaded) return;

    _isLoadingMore = true;
    
    try {
      List<SubscribedPlaceModel> morePlaces;
      
      // Check if we have a filter
      if (_currentFilterType != null) {
        morePlaces = await _repository.getMorePlacesByType(
          type: _currentFilterType!,
          limit: _pageSize,
          afterPlaceId: _allPlaces.isNotEmpty ? _allPlaces.last.id : null,
        );
      } else {
        morePlaces = await _repository.getMoreSubscribedPlaces(
          limit: _pageSize,
          afterPlaceId: _allPlaces.isNotEmpty ? _allPlaces.last.id : null,
        );
      }

      if (morePlaces.isNotEmpty) {
        _allPlaces.addAll(morePlaces);
        _hasMoreData = morePlaces.length >= _pageSize;
        
        emit(SubscriptionLoaded(
          places: _allPlaces,
          settings: currentState.settings,
          statistics: currentState.statistics,
          hasMoreData: _hasMoreData,
          filterType: _currentFilterType,
        ));
      } else {
        _hasMoreData = false;
        emit(SubscriptionLoaded(
          places: _allPlaces,
          settings: currentState.settings,
          statistics: currentState.statistics,
          hasMoreData: false,
          filterType: _currentFilterType,
        ));
      }
    } catch (e) {
      emit(SubscriptionError('فشل في تحميل المزيد: $e'));
    } finally {
      _isLoadingMore = false;
    }
  }

  // Load places by type (with pagination)
  Future<void> loadPlacesByType(PlaceType type) async {
    emit(SubscriptionLoading());
    try {
      final settings = await _repository.getSettings();
      final statistics = await _repository.getStatistics();

      _allPlaces = [];
      _hasMoreData = true;
      _isLoadingMore = false;
      _currentFilterType = type; // Set current filter

      _placesSubscription?.cancel();
      _placesSubscription = _repository.getSubscribedPlacesByTypePaginated(
        type: type,
        limit: _pageSize,
      ).listen(
        (places) {
          _allPlaces = places;
          _hasMoreData = places.length >= _pageSize;
          emit(SubscriptionLoaded(
            places: places,
            settings: settings,
            statistics: statistics,
            hasMoreData: _hasMoreData,
            filterType: type,
          ));
        },
        onError: (error) {
          emit(SubscriptionError('فشل في تحميل الأماكن: $error'));
        },
      );
    } catch (e) {
      emit(SubscriptionError('فشل في تحميل البيانات: $e'));
    }
  }

  // Load place details with payment history
  Future<void> loadPlaceDetails(String placeId) async {
    emit(PaymentsLoading());
    try {
      final place = await _repository.getSubscribedPlaceById(placeId);
      final settings = await _repository.getSettings();

      if (place == null) {
        emit(SubscriptionError('المكان غير موجود'));
        return;
      }

      _paymentsSubscription?.cancel();
      _paymentsSubscription = _repository.getPaymentRecords(placeId).listen(
        (payments) {
          emit(PlaceDetailsLoaded(
            place: place,
            payments: payments,
            settings: settings,
          ));
        },
        onError: (error) {
          emit(SubscriptionError('فشل في تحميل سجلات الدفع: $error'));
        },
      );
    } catch (e) {
      emit(SubscriptionError('فشل في تحميل التفاصيل: $e'));
    }
  }

  // Refresh place details
  Future<void> refreshPlaceDetails(String placeId) async {
    try {
      final place = await _repository.getSubscribedPlaceById(placeId);
      final settings = await _repository.getSettings();

      if (place == null) {
        emit(SubscriptionError('المكان غير موجود'));
        return;
      }

      // Keep existing payments subscription
      final currentState = state;
      if (currentState is PlaceDetailsLoaded) {
        emit(PlaceDetailsLoaded(
          place: place,
          payments: currentState.payments,
          settings: settings,
        ));
      }
    } catch (e) {
      emit(SubscriptionError('فشل في تحديث التفاصيل: $e'));
    }
  }

  // Search places
  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      loadAllPlaces();
      return;
    }

    emit(PlacesLoading());
    try {
      final settings = await _repository.getSettings();
      final places = await _repository.searchPlaces(query);

      emit(SubscriptionLoaded(
        places: places,
        settings: settings,
        searchQuery: query,
      ));
    } catch (e) {
      emit(SubscriptionError('فشل في البحث: $e'));
    }
  }

  // Load expired subscriptions
  Future<void> loadExpiredSubscriptions() async {
    emit(PlacesLoading());
    try {
      final settings = await _repository.getSettings();

      _placesSubscription?.cancel();
      _placesSubscription = _repository.getExpiredSubscriptions().listen(
        (places) {
          emit(SubscriptionLoaded(
            places: places,
            settings: settings,
          ));
        },
        onError: (error) {
          emit(SubscriptionError('فشل في تحميل الاشتراكات المنتهية: $error'));
        },
      );
    } catch (e) {
      emit(SubscriptionError('فشل في تحميل البيانات: $e'));
    }
  }

  // ==================== Settings ====================

  // Update settings
  Future<void> updateSettings({
    required double monthlyPrice,
    required double yearlyPrice,
  }) async {
    try {
      final settings = SubscriptionSettingsModel(
        id: 'settings',
        monthlyPrice: monthlyPrice,
        yearlyPrice: yearlyPrice,
        updatedAt: DateTime.now(),
      );

      await _repository.updateSettings(settings);
      emit(SettingsUpdated('تم تحديث أسعار الاشتراك بنجاح'));
      loadAllPlaces();
    } catch (e) {
      emit(SubscriptionError('فشل في تحديث الإعدادات: $e'));
    }
  }

  // ==================== Payments ====================

  // Record a payment
  Future<void> recordPayment({
    required String subscribedPlaceId,
    required double amount,
    required PaymentType paymentType,
    required DateTime paymentDate,
    String? notes,
    String recordedBy = 'Admin',
  }) async {
    try {
      // Calculate subscription dates
      DateTime startDate = paymentDate;
      DateTime endDate;

      // Get current subscription end date to extend if still valid
      final place = await _repository.getSubscribedPlaceById(subscribedPlaceId);
      if (place != null && place.subscriptionEndDate != null && 
          place.subscriptionEndDate!.isAfter(paymentDate)) {
        startDate = place.subscriptionEndDate!;
      }

      switch (paymentType) {
        case PaymentType.monthly:
          endDate = DateTime(startDate.year, startDate.month + 1, startDate.day);
          break;
        case PaymentType.yearly:
          endDate = DateTime(startDate.year + 1, startDate.month, startDate.day);
          break;
        case PaymentType.custom:
          // For custom, we'll add 30 days per 100 EGP (or configured amount)
          final settings = await _repository.getSettings();
          final months = (amount / settings.monthlyPrice).floor();
          endDate = DateTime(startDate.year, startDate.month + months, startDate.day);
          break;
      }

      final record = PaymentRecordModel(
        id: '',
        subscribedPlaceId: subscribedPlaceId,
        amount: amount,
        paymentType: paymentType,
        paymentDate: paymentDate,
        subscriptionStartDate: startDate,
        subscriptionEndDate: endDate,
        notes: notes,
        recordedBy: recordedBy,
        createdAt: DateTime.now(),
      );

      await _repository.addPaymentRecord(record);
      emit(PaymentRecorded('تم تسجيل الدفع بنجاح'));
      // Reload places list to refresh the UI
      loadAllPlaces();
    } catch (e) {
      emit(SubscriptionError('فشل في تسجيل الدفع: $e'));
    }
  }

  // Delete a payment record
  Future<void> deletePaymentRecord(String id, String subscribedPlaceId, double amount) async {
    try {
      await _repository.deletePaymentRecord(id, subscribedPlaceId, amount);
      emit(PaymentDeleted('تم حذف سجل الدفع'));
      loadPlaceDetails(subscribedPlaceId);
    } catch (e) {
      emit(SubscriptionError('فشل في حذف سجل الدفع: $e'));
    }
  }

  // ==================== Notes ====================

  // Update place notes
  Future<void> updatePlaceNotes(String placeId, String notes) async {
    try {
      await _repository.updatePlaceNotes(placeId, notes);
      emit(NotesUpdated('تم حفظ الملاحظات'));
      refreshPlaceDetails(placeId);
    } catch (e) {
      emit(SubscriptionError('فشل في حفظ الملاحظات: $e'));
    }
  }

  // ==================== Sync ====================

  // Sync all places from collections
  Future<void> syncAllPlaces() async {
    emit(SyncingPlaces());
    try {
      final beforeCount = (await _repository.getStatistics())['totalPlaces'] as int;
      await _repository.syncAllPlaces();
      final afterCount = (await _repository.getStatistics())['totalPlaces'] as int;
      final syncedCount = afterCount - beforeCount;

      emit(PlacesSynced('تم مزامنة الأماكن بنجاح', syncedCount));
      loadAllPlaces();
    } catch (e) {
      emit(SubscriptionError('فشل في مزامنة الأماكن: $e'));
    }
  }

  // Sync places of specific type
  Future<void> syncPlacesOfType(PlaceType type) async {
    emit(SyncingPlaces());
    try {
      await _repository.syncPlacesOfType(type);
      emit(PlacesSynced('تم مزامنة ${type.arabicName} بنجاح', 0));
      loadAllPlaces();
    } catch (e) {
      emit(SubscriptionError('فشل في المزامنة: $e'));
    }
  }

  // ==================== Delete ====================

  // Delete a subscribed place
  Future<void> deletePlace(String placeId) async {
    try {
      await _repository.deleteSubscribedPlace(placeId);
      emit(PlaceDeleted('تم حذف المكان من سجل الاشتراكات'));
      loadAllPlaces();
    } catch (e) {
      emit(SubscriptionError('فشل في حذف المكان: $e'));
    }
  }

  // ==================== Cleanup ====================

  @override
  Future<void> close() {
    _placesSubscription?.cancel();
    _paymentsSubscription?.cancel();
    return super.close();
  }
}
