import 'package:flutter/material.dart';
import '../../data/models/subscribed_place_model.dart';
import 'detail_info_row.dart';

class PlaceInfoCardWidget extends StatelessWidget {
  final SubscribedPlaceModel place;
  final VoidCallback onEdit;

  const PlaceInfoCardWidget({
    super.key,
    required this.place,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getTypeColor(place.placeType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTypeIcon(place.placeType),
                        size: 16,
                        color: _getTypeColor(place.placeType),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        place.placeType.arabicName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getTypeColor(place.placeType),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _buildStatusBadge(place.subscriptionStatus),
              ],
            ),
            const Divider(height: 24),

            DetailInfoRow(icon: Icons.person, label: 'صاحب المكان', value: place.ownerName),
            DetailInfoRow(icon: Icons.phone, label: 'رقم الهاتف', value: place.phone),
            if (place.email != null && place.email!.isNotEmpty)
              DetailInfoRow(icon: Icons.email, label: 'البريد الإلكتروني', value: place.email!),
            if (place.address != null && place.address!.isNotEmpty)
              DetailInfoRow(icon: Icons.location_on, label: 'العنوان', value: place.address!),
            if (place.governorate != null || place.city != null)
              DetailInfoRow(
                icon: Icons.map,
                label: 'المنطقة',
                value: [place.governorate, place.city]
                    .where((e) => e != null && e.isNotEmpty)
                    .join(' - '),
              ),
            
            const Divider(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('تعديل بيانات المكان'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'فعال':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'ينتهي قريباً':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case 'منتهي':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(PlaceType type) {
    switch (type) {
      case PlaceType.clinic:
        return const Color(0xFF10B981);
      case PlaceType.pharmacy:
        return const Color(0xFF6366F1);
      case PlaceType.laboratory:
        return const Color(0xFF8B5CF6);
      case PlaceType.radiology:
        return const Color(0xFFEC4899);
      case PlaceType.nursing:
        return const Color(0xFF14B8A6);
      case PlaceType.delivery:
        return const Color(0xFF3B82F6);
      case PlaceType.rehabilitation:
        return const Color(0xFF7C3AED);
      case PlaceType.gym:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _getTypeIcon(PlaceType type) {
    switch (type) {
      case PlaceType.clinic:
        return Icons.local_hospital;
      case PlaceType.pharmacy:
        return Icons.medication;
      case PlaceType.laboratory:
        return Icons.science;
      case PlaceType.radiology:
        return Icons.medical_services;
      case PlaceType.nursing:
        return Icons.health_and_safety;
      case PlaceType.delivery:
        return Icons.local_shipping;
      case PlaceType.rehabilitation:
        return Icons.accessibility_new;
      case PlaceType.gym:
        return Icons.fitness_center;
    }
  }
}
