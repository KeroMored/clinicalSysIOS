import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/gym_model.dart';

class GymFeaturesCard extends StatelessWidget {
  final GymModel gym;

  const GymFeaturesCard({super.key, required this.gym});

  @override
  Widget build(BuildContext context) {
    final features = <Map<String, dynamic>>[];

    if (gym.hasPersonalTraining) {
      features.add({'icon': Icons.person_rounded, 'title': 'تدريب شخصي'});
    }
    if (gym.hasNutritionConsultation) {
      features.add({
        'icon': Icons.restaurant_rounded,
        'title': 'استشارات تغذية',
      });
    }
    if (gym.hasSwimmingPool) {
      features.add({'icon': Icons.pool_rounded, 'title': 'حمام سباحة'});
    }
    if (gym.hasSauna) {
      features.add({'icon': Icons.hot_tub_rounded, 'title': 'ساونا'});
    }
    if (gym.hasSteamRoom) {
      features.add({'icon': Icons.cloud_rounded, 'title': 'غرفة بخار'});
    }
    if (gym.hasYogaClasses) {
      features.add({
        'icon': Icons.self_improvement_rounded,
        'title': 'حصص يوجا',
      });
    }
    if (gym.hasCrossFit) {
      features.add({
        'icon': Icons.sports_gymnastics_rounded,
        'title': 'كروس فيت',
      });
    }
    if (gym.hasMartialArts) {
      features.add({
        'icon': Icons.sports_martial_arts_rounded,
        'title': 'فنون قتالية',
      });
    }
    if (gym.hasCardio) {
      features.add({
        'icon': Icons.directions_run_rounded,
        'title': 'كارديو (تمارين التخسيس)',
      });
    }
    if (gym.hasWeightLifting) {
      features.add({
        'icon': Icons.fitness_center_rounded,
        'title': 'رفع الأثقال',
      });
    }
    if (gym.hasBodybuilding) {
      features.add({
        'icon': Icons.sports_gymnastics_rounded,
        'title': 'كمال أجسام',
      });
    }
    if (gym.hasFunctionalTraining) {
      features.add({'icon': Icons.sports_rounded, 'title': 'تدريب وظيفي'});
    }
    if (gym.hasGroupClasses) {
      features.add({'icon': Icons.groups_rounded, 'title': 'حصص جماعية'});
    }

    if (features.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.gymGradient.colors[0].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: AppTheme.gymGradient.colors[0],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'المميزات الإضافية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: features.map((feature) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.gymGradient.colors[0].withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.gymGradient.colors[0].withValues(
                      alpha: 0.2,
                    ),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      feature['icon'] as IconData,
                      size: 20,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      feature['title'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
