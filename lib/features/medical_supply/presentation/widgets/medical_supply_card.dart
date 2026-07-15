import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/medical_supply_model.dart';
import '../../../../core/utils/pharmacy_hours_helper.dart';
import '../../../../core/services/location_service.dart';

class MedicalSupplyCard extends StatelessWidget {
  final MedicalSupplyModel supply;
  final VoidCallback onTap;
  final Position? userLocation;

  const MedicalSupplyCard({
    super.key,
    required this.supply,
    required this.onTap,
    this.userLocation,
  });

  String _formatDistance() {
    if (userLocation == null) {
      return '-- كم';
    }

    final distance = LocationService.calculateDistance(
      userLocation!.latitude,
      userLocation!.longitude,
      supply.latitude,
      supply.longitude,
    );

    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} م';
    }

    return '${distance.toStringAsFixed(1)} كم';
  }

  @override
  Widget build(BuildContext context) {
    final isActuallyOpen = PharmacyHoursHelper.isPharmacyOpen(
      workingHours: supply.workingHours,
      holidays: supply.holidays,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.merge(
          Border(right: BorderSide(color: Colors.teal, width: 1.5)),
          Border(bottom: BorderSide(color: Colors.teal, width: 2.5)),
        ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFF2563EB),
                            size: 14,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            (supply.averageRating > 0
                                    ? supply.averageRating
                                    : 0.0)
                                .toStringAsFixed(1),
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActuallyOpen
                            ? const Color(0xFFDDF7EC)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isActuallyOpen ? 'مفتوح الآن' : 'مغلق الآن',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isActuallyOpen
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF06B6D4),
                            Color.fromARGB(255, 9, 46, 55),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supply.name,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 15,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${supply.address} - ${supply.center}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.near_me_rounded,
                      size: 14,
                      color: Color(0xFF0EA5A4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDistance(),
                      style: const TextStyle(
                        color: Color(0xFF0EA5A4),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (supply.services.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.medical_information_rounded,
                        size: 14,
                        color: Color(0xFF06B6D4),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${supply.services.length} خدمات متوفرة',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (supply.hasHomeDelivery) ...[
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'خدمة التوصيل متاحة',
                      style: TextStyle(
                        color: Color(0xFF15803D),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isActuallyOpen ? onTap : null,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      backgroundColor: const Color(0xFF0B8293),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: Text(
                      isActuallyOpen ? 'عرض التفاصيل' : 'مغلق الآن',
                      style: TextStyle(
                        color: isActuallyOpen
                            ? Colors.white
                            : const Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
