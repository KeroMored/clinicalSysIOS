import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/pharmacy_model.dart';
import '../../../../core/utils/pharmacy_hours_helper.dart';
import '../../../../core/services/location_service.dart';

class PharmacyCard extends StatelessWidget {
  final PharmacyModel pharmacy;
  final VoidCallback onTap;
  final Position? userLocation;

  const PharmacyCard({
    super.key,
    required this.pharmacy,
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
      pharmacy.latitude,
      pharmacy.longitude,
    );

    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} م';
    }

    return '${distance.toStringAsFixed(1)} كم';
  }

  @override
  Widget build(BuildContext context) {
    final isActuallyOpen = PharmacyHoursHelper.isPharmacyOpen(
      workingHours: pharmacy.workingHours,
      holidays: pharmacy.holidays,
    );

    final insuranceText = pharmacy.hasInsurance
        ? '${pharmacy.insuranceCompanies.length} شركات متعاقدة'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.merge(
          Border(right: BorderSide(color: Colors.teal, width: 1.5)),
          Border(bottom: BorderSide(color: Colors.teal, width: 2.5)),
        ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withValues(alpha: 0.06),
        //     blurRadius: 50,
        //     offset: const Offset(1, 1),
        //   ),
        // ],
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
                            (pharmacy.averageRating > 0
                                    ? pharmacy.averageRating
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
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset(
                          'assets/images/pharmacy.svg',
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pharmacy.name,
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
                                  '${pharmacy.address} - ${pharmacy.center}',
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
                    const SizedBox(width: 10),
                    pharmacy.hasInsurance
                        ? const Icon(
                            Icons.verified_user_rounded,
                            size: 14,
                            color: Color(0xFF06B6D4),
                          )
                        : Container(),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        insuranceText,
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
                ),
                if (pharmacy.hasHomeDelivery) ...[
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
                      isActuallyOpen ? 'عرض الصيدلية' : 'مغلق الآن',
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
