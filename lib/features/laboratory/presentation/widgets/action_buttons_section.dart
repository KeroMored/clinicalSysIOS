import 'package:flutter/material.dart';
import '../../data/models/laboratory_model.dart';
import '../screens/laboratory_home_page.dart';
import '../screens/edit_laboratory_screen.dart';
import 'action_card.dart';

class ActionButtonsSection extends StatelessWidget {
  final LaboratoryModel laboratory;
  final VoidCallback onUpdate;
  final VoidCallback onShowAvailableTests;
  final VoidCallback onShowWorkingHours;

  const ActionButtonsSection({
    super.key,
    required this.laboratory,
    required this.onUpdate,
    required this.onShowAvailableTests,
    required this.onShowWorkingHours,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'إجراءات سريعة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: ActionCard(
                icon: Icons.visibility,
                label: 'عرض صفحة المعمل',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LaboratoryDetailsScreen(
                        laboratory: laboratory,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActionCard(
                icon: Icons.edit,
                label: 'تعديل البيانات',
                color: Colors.orange,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditLaboratoryScreen(
                        laboratory: laboratory,
                      ),
                    ),
                  );
                  if (result == true) {
                    onUpdate();
                  }
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: ActionCard(
                icon: Icons.biotech,
                label: 'إدارة التحاليل',
                color: Colors.purple,
                onTap: onShowAvailableTests,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActionCard(
                icon: Icons.access_time,
                label: 'مواعيد العمل',
                color: Colors.teal,
                onTap: onShowWorkingHours,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
