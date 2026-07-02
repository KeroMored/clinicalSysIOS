import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/radiology_model.dart';
import 'radiology_info_row.dart';

class RadiologyLocationCard extends StatelessWidget {
  final RadiologyModel radiology;

  const RadiologyLocationCard({super.key, required this.radiology});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الموقع',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const Divider(),
            RadiologyInfoRow(
              icon: Icons.location_city,
              label: 'المحافظة',
              value: radiology.governorate,
            ),
            RadiologyInfoRow(
              icon: Icons.location_on,
              label: 'المدينة',
              value: radiology.city,
            ),
            RadiologyInfoRow(
              icon: Icons.map,
              label: 'العنوان',
              value: radiology.address,
            ),
            RadiologyInfoRow(
              icon: Icons.gps_fixed,
              label: 'الإحداثيات',
              value:
                  '${radiology.latitude.toStringAsFixed(6)}, ${radiology.longitude.toStringAsFixed(6)}',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _makePhoneCall(context, radiology.centerPhone),
                    icon: const Icon(Icons.phone),
                    label: const Text('اتصال'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _openWhatsApp(context, radiology.centerWhatsApp),
                    icon: Icon(Icons.chat_bubble),
                    label: const Text('واتساب'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _openMap(context, radiology.latitude, radiology.longitude),
                icon: const Icon(Icons.map),
                label: const Text('فتح الموقع في الخريطة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatWhatsAppNumber(String input) {
    // خد الرقم زي ما هو وضيفله +20 فقط
    String n = input.trim();
    // لو بيبدأ بـ + شيله
    if (n.startsWith('+')) n = n.substring(1);
    // لو بيبدأ بـ 20 يبقى خلاص
    if (n.startsWith('20')) return '20$n';
    // ضيف +20 قدام الرقم
    return '20$n';
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن إجراء المكالمة')));
      }
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phoneNumber) async {
    final formatted = _formatWhatsAppNumber(phoneNumber);
    if (formatted.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('رقم واتساب غير صحيح')));
      }
      return;
    }
    final String whatsappUrl = "https://wa.me/$formatted";
    try {
      bool launched = await launchUrl(Uri.parse(whatsappUrl));
      if (!launched) {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح واتساب')));
      }
    }
  }

  Future<void> _openMap(BuildContext context, double lat, double lng) async {
    final Uri mapUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح الخريطة')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }
}
