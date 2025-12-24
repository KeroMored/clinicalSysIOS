import 'package:flutter/material.dart';
import '../../data/models/laboratory_model.dart';
import '../screens/edit_laboratory_screen.dart';
import 'info_row.dart';

class LaboratoryInfoCard extends StatelessWidget {
  final LaboratoryModel laboratory;
  final VoidCallback onUpdate;

  const LaboratoryInfoCard({
    super.key,
    required this.laboratory,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(laboratory.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(laboratory.status),
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusText(laboratory.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
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
                  icon: const Icon(Icons.edit),
                  color: Colors.blue,
                  tooltip: 'تعديل البيانات',
                ),
              ],
            ),
            const Divider(height: 30),
            
            InfoRow(
              icon: Icons.science,
              label: 'اسم المعمل',
              value: laboratory.name,
            ),
            const SizedBox(height: 16),
            
            InfoRow(
              icon: Icons.person,
              label: 'اسم المالك',
              value: laboratory.ownerName,
            ),
            const SizedBox(height: 16),
            
            InfoRow(
              icon: Icons.location_on,
              label: 'العنوان',
              value: laboratory.address,
            ),
            const SizedBox(height: 16),
            
            InfoRow(
              icon: Icons.phone,
              label: 'رقم الهاتف',
              value: laboratory.ownerPhone,
            ),
            const SizedBox(height: 16),
            
            InfoRow(
              icon: Icons.biotech,
              label: 'عدد التحاليل المتاحة',
              value: '${laboratory.availableTests.length} تحليل',
            ),
            
            if (laboratory.hasHomeService) ...[
              const SizedBox(height: 16),
              InfoRow(
                icon: Icons.home,
                label: 'خدمة منزلية',
                value: laboratory.homeServiceFee != null
                    ? 'متاحة (${laboratory.homeServiceFee} جنيه)'
                    : 'متاحة',
                valueColor: Colors.blue,
              ),
            ],
            
            if (laboratory.description != null && laboratory.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              InfoRow(
                icon: Icons.description,
                label: 'الوصف',
                value: laboratory.description!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.access_time;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      default:
        return 'قيد الانتظار';
    }
  }
}
