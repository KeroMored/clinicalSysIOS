import 'package:flutter/material.dart';
import 'package:clinicalsystem/features/pharmacy/data/models/pharmacy_offer_model.dart';
import 'package:clinicalsystem/features/clinic/data/models/clinic_offer_model.dart';
import '../services/generic_offer_sorting_service.dart';

enum OfferType {
  pharmacy,
  clinic,
  gym,
  medicalSupply,
}

/// Unified wrapper للعروض من جميع المصادر
class UnifiedOfferModel implements ISortableOffer {
  final String offerId;
  final OfferType offerType;
  final String sourceId; // pharmacyId, clinicId, or gymId
  final String sourceName; // pharmacy name, clinic/doctor name, gym name
  final String title;
  final String description;
  final String notes;
  final List<String> images;
  @override
  final String id;
  @override
  final DateTime createdAt;
  @override
  final int viewsCount;
  @override
  final String category;
  final bool isActive;

  UnifiedOfferModel({
    required this.offerId,
    required this.offerType,
    required this.sourceId,
    required this.sourceName,
    required this.title,
    required this.description,
    required this.notes,
    required this.images,
    required this.id,
    required this.createdAt,
    required this.viewsCount,
    required this.category,
    required this.isActive,
  });

  /// Create from PharmacyOfferModel
  factory UnifiedOfferModel.fromPharmacy(PharmacyOfferModel pharmacy) {
    return UnifiedOfferModel(
      offerId: pharmacy.id,
      offerType: OfferType.pharmacy,
      sourceId: pharmacy.pharmacyId,
      sourceName: pharmacy.pharmacyName,
      title: pharmacy.title,
      description: pharmacy.description,
      notes: pharmacy.notes,
      images: pharmacy.images,
      id: pharmacy.id,
      createdAt: pharmacy.createdAt,
      viewsCount: pharmacy.viewsCount,
      category: pharmacy.category,
      isActive: pharmacy.isActive,
    );
  }

  /// Create from ClinicOfferModel
  factory UnifiedOfferModel.fromClinic(ClinicOfferModel clinic) {
    return UnifiedOfferModel(
      offerId: clinic.id,
      offerType: OfferType.clinic,
      sourceId: clinic.clinicId,
      sourceName: clinic.displayName, // استخدام displayName بدلاً من doctorName
      title: clinic.title,
      description: clinic.description,
      notes: clinic.notes,
      images: clinic.images,
      id: clinic.id,
      createdAt: clinic.createdAt,
      viewsCount: clinic.viewsCount,
      category: clinic.category,
      isActive: clinic.isActive,
    );
  }

  String get collectionName {
    switch (offerType) {
      case OfferType.pharmacy:
        return 'offers';
      case OfferType.clinic:
        return 'clinic_offers';
      case OfferType.gym:
        return 'gym_offers';
      case OfferType.medicalSupply:
        return 'medical_supply_offers';
    }
  }

  IconData get sourceIcon {
    switch (offerType) {
      case OfferType.pharmacy:
        return Icons.local_pharmacy_rounded;
      case OfferType.clinic:
        return Icons.local_hospital_rounded;
      case OfferType.gym:
        return Icons.fitness_center_rounded;
      case OfferType.medicalSupply:
        return Icons.medical_services_rounded;
    }
  }

  String get sourceTypeLabel {
    switch (offerType) {
      case OfferType.pharmacy:
        return 'صيدلية';
      case OfferType.clinic:
        return 'عيادة';
      case OfferType.gym:
        return 'جيم';
      case OfferType.medicalSupply:
        return 'مستلزمات طبية';
    }
  }
}
