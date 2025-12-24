import 'package:flutter/material.dart';
import '../../data/models/subscribed_place_model.dart';

class SubscriptionStatsCard extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const SubscriptionStatsCard({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'إحصائيات الاشتراكات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main stats
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.store,
                    value: statistics['totalPlaces']?.toString() ?? '0',
                    label: 'إجمالي الأماكن',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.check_circle,
                    value: statistics['activePlaces']?.toString() ?? '0',
                    label: 'اشتراك فعال',
                    valueColor: Colors.lightGreenAccent,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.warning,
                    value: statistics['expiringPlaces']?.toString() ?? '0',
                    label: 'ينتهي قريباً',
                    valueColor: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.cancel,
                    value: statistics['expiredPlaces']?.toString() ?? '0',
                    label: 'منتهي',
                    valueColor: Colors.red[300],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Revenue
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.payments,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إجمالي الإيرادات',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '${(statistics['totalRevenue'] ?? 0).toStringAsFixed(0)} ج.م',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'عدد الدفعات',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '${statistics['totalPayments'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Count by type
            _buildTypeCountsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTypeCountsRow() {
    final countByType = statistics['countByType'] as Map<PlaceType, int>?;
    if (countByType == null || countByType.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: countByType.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getTypeIcon(entry.key), size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                '${entry.key.arabicName}: ${entry.value}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
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
