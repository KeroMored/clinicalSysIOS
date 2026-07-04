import 'package:flutter/material.dart';
import '../../data/models/radiology_model.dart';
import 'radiology_info_row.dart';

class RadiologyBasicInfoCard extends StatelessWidget {
  final RadiologyModel radiology;

  const RadiologyBasicInfoCard({super.key, required this.radiology});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المعلومات الأساسية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const Divider(),
            RadiologyInfoRow(
              icon: Icons.business,
              label: 'اسم المركز',
              value: radiology.centerName,
            ),
            RadiologyInfoRow(
              icon: Icons.phone,
              label: 'هاتف المركز',
              value: radiology.centerPhone,
            ),
            RadiologyInfoRow(
              icon: Icons.chat,
              label: 'واتساب المركز',
              value: radiology.centerWhatsApp,
            ),
            RadiologyInfoRow(
              icon: Icons.person,
              label: 'اسم المالك',
              value: radiology.ownerName,
            ),
            RadiologyInfoRow(
              icon: Icons.phone,
              label: 'هاتف المالك',
              value: radiology.ownerPhone,
            ),
            RadiologyInfoRow(
              icon: Icons.email,
              label: 'البريد الإلكتروني',
              value: radiology.authEmails.isNotEmpty
                  ? radiology.authEmails.first
                  : 'غير متوفر',
            ),
            if (radiology.licenseNumber != null)
              RadiologyInfoRow(
                icon: Icons.card_membership,
                label: 'رقم الترخيص',
                value: radiology.licenseNumber!,
              ),
          ],
        ),
      ),
    );
  }
}
