import 'package:flutter/material.dart';
import '../../data/models/subscribed_place_model.dart';

class PlaceSubscriptionCard extends StatelessWidget {
  final SubscribedPlaceModel place;
  final VoidCallback? onTap;
  final VoidCallback? onPaymentTap;

  const PlaceSubscriptionCard({
    super.key,
    required this.place,
    this.onTap,
    this.onPaymentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with type badge and status
              Row(
                children: [
                  _buildTypeBadge(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      place.placeName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 12),

              // Owner and phone
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      place.ownerName,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    place.phone,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Location
              if (place.governorate != null || place.city != null)
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        [place.governorate, place.city]
                            .where((e) => e != null && e.isNotEmpty)
                            .join(' - '),
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),

              // Payment info and action
              Row(
                children: [
                  // Total paid
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payments_outlined, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          '${place.totalPaid.toStringAsFixed(0)} ج.م',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Payment count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${place.paymentCount} دفعة',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Add payment button
                  if (onPaymentTap != null)
                    ElevatedButton.icon(
                      onPressed: onPaymentTap,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('دفع'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                ],
              ),

              // Subscription end date
              if (place.subscriptionEndDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 14,
                      color: place.isSubscriptionExpired ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ينتهي: ${_formatDate(place.subscriptionEndDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: place.isSubscriptionExpired ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],

              // Notes preview
              if (place.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.note_outlined, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          place.notes,
                          style: const TextStyle(fontSize: 12, color: Colors.amber),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTypeColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getTypeIcon(), size: 14, color: _getTypeColor()),
          const SizedBox(width: 4),
          Text(
            place.placeType.arabicName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _getTypeColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color statusColor;
    IconData statusIcon;

    switch (place.subscriptionStatus) {
      case 'فعال':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'ينتهي قريباً':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      case 'منتهي':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 14, color: statusColor),
          const SizedBox(width: 4),
          Text(
            place.subscriptionStatus,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (place.placeType) {
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

  IconData _getTypeIcon() {
    switch (place.placeType) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
