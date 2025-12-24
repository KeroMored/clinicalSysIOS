import 'package:flutter/material.dart';
import '../widgets/subscription_stats_card.dart';
import 'quick_action_card.dart';

class StatisticsTabWidget extends StatelessWidget {
  final Map<String, dynamic>? statistics;
  final VoidCallback onExpiredTap;
  final VoidCallback onExpiringSoonTap;

  const StatisticsTabWidget({
    super.key,
    required this.statistics,
    required this.onExpiredTap,
    required this.onExpiringSoonTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (statistics != null)
            SubscriptionStatsCard(statistics: statistics!),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.warning_amber,
                    title: 'منتهي الاشتراك',
                    subtitle: '${statistics?['expiredPlaces'] ?? 0} مكان',
                    color: Colors.red,
                    onTap: onExpiredTap,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.timer,
                    title: 'ينتهي قريباً',
                    subtitle: '${statistics?['expiringPlaces'] ?? 0} مكان',
                    color: Colors.orange,
                    onTap: onExpiringSoonTap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
