import 'package:flutter/material.dart';
import '../../data/models/subscribed_place_model.dart';
import '../../data/models/subscription_settings_model.dart';
import '../widgets/subscription_settings_card.dart';

class SettingsTabWidget extends StatelessWidget {
  final SubscriptionSettingsModel settings;
  final Function(double monthly, double yearly) onSave;

  const SettingsTabWidget({
    super.key,
    required this.settings,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SubscriptionSettingsCard(
            settings: settings,
            onSave: onSave,
          ),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'مزامنة سريعة حسب النوع',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PlaceType.values.map((type) {
                return ElevatedButton.icon(
                  onPressed: () {
                    // Sync functionality handled by parent
                  },
                  icon: Icon(_getTypeIcon(type), size: 18),
                  label: Text(type.arabicName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getTypeColor(type),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
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
