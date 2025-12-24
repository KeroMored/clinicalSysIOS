import 'package:flutter/material.dart';
import '../../data/models/radiology_model.dart';
import 'radiology_info_row.dart';

class RadiologyLicenseCard extends StatelessWidget {
  final RadiologyModel radiology;

  const RadiologyLicenseCard({
    super.key,
    required this.radiology,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات الترخيص',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const Divider(),
            if (radiology.licenseNumber != null)
              RadiologyInfoRow(icon: Icons.card_membership, label: 'رقم الترخيص', value: radiology.licenseNumber!),
            if (radiology.licenseImageUrl != null) ...[
              const SizedBox(height: 12),
              const Text(
                'صورة الترخيص:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  radiology.licenseImageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.error_outline, size: 48, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (radiology.licenseNumber == null && radiology.licenseImageUrl == null)
              const Center(child: Text('لا توجد معلومات ترخيص')),
          ],
        ),
      ),
    );
  }
}
