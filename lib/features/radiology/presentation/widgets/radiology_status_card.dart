import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/radiology_model.dart';

class RadiologyStatusCard extends StatelessWidget {
  final RadiologyModel radiology;

  const RadiologyStatusCard({
    super.key,
    required this.radiology,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: radiology.isApproved ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              radiology.isApproved ? Icons.check_circle : Icons.pending,
              size: 48,
              color: radiology.isApproved ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    radiology.isApproved ? 'مركز معتمد' : 'في انتظار الموافقة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: radiology.isApproved ? Colors.green.shade900 : Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تاريخ التسجيل: ${DateFormat('yyyy-MM-dd').format(radiology.createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
