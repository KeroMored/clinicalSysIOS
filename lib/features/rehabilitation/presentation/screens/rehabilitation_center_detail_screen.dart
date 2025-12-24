import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/rehabilitation_center_model.dart';
import 'center_works_screen.dart';
import '../../../../core/widgets/rating_widget.dart';
import '../../../../core/widgets/like_button.dart';
import '../../../../core/widgets/report_button.dart';

class RehabilitationCenterDetailScreen extends StatefulWidget {
  final RehabilitationCenterModel center;

  const RehabilitationCenterDetailScreen({super.key, required this.center});

  @override
  State<RehabilitationCenterDetailScreen> createState() => _RehabilitationCenterDetailScreenState();
}

class _RehabilitationCenterDetailScreenState extends State<RehabilitationCenterDetailScreen> {
  late RehabilitationCenterModel _center;

  @override
  void initState() {
    super.initState();
    _center = widget.center;
  }

  Future<void> _refreshCenterData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('rehabilitation_centers')
          .doc(_center.id)
          .get();
      
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        setState(() {
          _center = RehabilitationCenterModel.fromMap(data);
        });
      }
    } catch (e) {
      print('Error refreshing center data: $e');
    }
  }

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

  Future<void> _openGoogleMaps(BuildContext context, double latitude, double longitude) async {
    final Uri mapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح خرائط جوجل')),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Modern AppBar with image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image or Gradient
                  if (_center.profileImageUrl != null)
                    Image.network(
                      _center.profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                        ),
                      ),
                    ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Center Info at Bottom
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _center.centerName,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 8,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.white70, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              _center.directorName,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white70,
                              ),
                            ),
                            if (_center.hasHomeService) ...[
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.home, size: 14, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'خدمة منزلية',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                
                // Rating, Likes, Report Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: RatingWidget(
                              serviceId: _center.id,
                              serviceType: 'rehabilitation',
                              averageRating: _center.averageRating,
                              totalRatings: _center.totalRatings,
                              starSize: 22,
                              onRatingAdded: () {
                                // Refresh center data after rating
                                _refreshCenterData();
                              },
                            ),
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey[300],
                          ),
                          LikeButton(
                            serviceId: _center.id,
                            serviceType: 'rehabilitation',
                            initialLikesCount: _center.totalLikes,
                            iconSize: 26,
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey[300],
                          ),
                          ReportButton(
                            serviceId: _center.id,
                            serviceType: 'rehabilitation',
                            serviceName: _center.centerName,
                            iconSize: 26,
                            showLabel: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // About Section
                _buildInfoSection(
                  context,
                  title: 'نبذة عن المركز',
                  icon: Icons.info_outline,
                  children: [
                    Text(
                      _center.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CenterWorksScreen(
                              centerId: _center.id,
                              centerName: _center.centerName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('أعمالنا وعروضنا'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),

                // Service Types Section
                _buildInfoSection(
                  context,
                  title: 'الخدمات المتوفرة',
                  icon: Icons.medical_services,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _center.serviceTypes.map((service) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            service,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // Location Section
                _buildInfoSection(
                  context,
                  title: 'الموقع',
                  icon: Icons.location_on,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.place, color: Colors.red[700], size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _center.address,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[800],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _openGoogleMaps(context, _center.latitude, _center.longitude),
                      icon: const Icon(Icons.map),
                      label: const Text('فتح في خرائط جوجل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),

                // Contact Section
                _buildInfoSection(
                  context,
                  title: 'معلومات الاتصال',
                  icon: Icons.phone,
                  children: [
                    _buildContactTile(Icons.phone, 'الهاتف', _center.phone),
                    if (_center.whatsapp != null) ...[
                      const SizedBox(height: 12),
                      _buildContactTile(MdiIcons.whatsapp, 'واتساب', _center.whatsapp!),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _makePhoneCall(context, _center.phone),
                            icon: const Icon(Icons.phone),
                            label: const Text('مكالمة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (_center.whatsapp != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openWhatsApp(context, _center.whatsapp!),
                              icon: Icon(MdiIcons.whatsapp),
                              label: const Text('واتساب'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
