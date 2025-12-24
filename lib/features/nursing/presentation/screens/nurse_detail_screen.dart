import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/nurse_model.dart';

class NurseDetailScreen extends StatelessWidget {
  final NurseModel nurse;

  const NurseDetailScreen({super.key, required this.nurse});

  String _formatWhatsAppNumber(String phoneNumber) {
    String formatted = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    formatted = formatted.replaceAll('+', '');
    if (formatted.startsWith('00')) {
      formatted = formatted.substring(2);
    }
    if (formatted.startsWith('0')) {
      formatted = '20${formatted.substring(1)}';
    }
    if (!formatted.startsWith('20')) {
      formatted = '20$formatted';
    }
    return formatted;
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن إجراء المكالمة')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phoneNumber) async {
    final String formattedNumber = _formatWhatsAppNumber(phoneNumber);
    final Uri whatsappUri = Uri.parse('https://wa.me/$formattedNumber');
    try {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح واتساب')),
        );
      }
    }
  }

  Future<void> _openMap(BuildContext context, double latitude, double longitude) async {
    final Uri mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    try {
      await launchUrl(mapUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح الخريطة')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nurse.nurseName),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(),
                  const SizedBox(height: 20),
                  _buildAboutSection(),
                  const SizedBox(height: 20),
                  _buildServicesSection(),
                  const SizedBox(height: 20),
                  _buildContactSection(context),
                  if (nurse.latitude != null && nurse.longitude != null) ...[
                    const SizedBox(height: 20),
                    _buildMapSection(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal.shade400, Colors.teal.shade700],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white,
            backgroundImage: nurse.profileImageUrl != null
                ? NetworkImage(nurse.profileImageUrl!)
                : null,
            child: nurse.profileImageUrl == null
                ? Icon(
                    nurse.gender == 'male' ? Icons.person : Icons.person_outline,
                    size: 60,
                    color: Colors.teal,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            nurse.nurseName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nurse.specialization,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (nurse.availableNow)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'متاح الآن',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              if (nurse.available24Hours && !nurse.availableNow) ...[
                if (nurse.availableNow) const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'متاح 24 ساعة',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات عامة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const Divider(),
            _buildInfoRow(Icons.work_history, 'سنوات الخبرة', '${nurse.yearsOfExperience} سنوات'),
            _buildInfoRow(Icons.person, 'النوع', nurse.gender == 'male' ? 'ممرض' : 'ممرضة'),
            _buildInfoRow(Icons.payments, 'السعر بالساعة', '${nurse.hourlyRate.toInt()} جنيه'),
            _buildInfoRow(Icons.location_on, 'العنوان', nurse.address),
            _buildInfoRow(Icons.location_city, 'المدينة', '${nurse.city}, ${nurse.governorate}'),
            if (nurse.licenseNumber != null)
              _buildInfoRow(Icons.card_membership, 'رقم الترخيص', nurse.licenseNumber!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    if (nurse.about.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'نبذة عن الممرض/ة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const Divider(),
            Text(
              nurse.about,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    if (nurse.services.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الخدمات المتاحة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const Divider(),
            ...nurse.services.map((service) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20, color: Colors.teal.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        service,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات التواصل',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const Divider(),
            _buildInfoRow(Icons.phone, 'رقم الهاتف', nurse.nursePhone),
            _buildInfoRow(MdiIcons.whatsapp, 'واتساب', nurse.nurseWhatsApp),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(context, nurse.nursePhone),
                    icon: const Icon(Icons.phone),
                    label: const Text('مكالمة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openWhatsApp(context, nurse.nurseWhatsApp),
                    icon: Icon(MdiIcons.whatsapp),
                    label: const Text('واتساب'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الموقع على الخريطة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const Divider(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openMap(context, nurse.latitude!, nurse.longitude!),
                icon: const Icon(Icons.map),
                label: const Text('فتح الموقع في الخريطة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
