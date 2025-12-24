import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/models/gym_model.dart';
import '../pages/gym_works_screen.dart';

class GymDescriptionCard extends StatelessWidget {
  final GymModel gym;

  const GymDescriptionCard({
    super.key,
    required this.gym,
  });

  @override
  Widget build(BuildContext context) {
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
                  Icons.info_outline_rounded,
                  color: AppTheme.gymGradient.colors[0],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'عن الجيم',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            gym.description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GradientButton(
              text: 'أعمالنا وعروضنا',
              icon: Icons.photo_library_rounded,
              gradient: const LinearGradient(
                colors: [Color.fromARGB(255, 0, 0, 0), Color(0xFF434343)],
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GymWorksScreen(gymId: gym.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
