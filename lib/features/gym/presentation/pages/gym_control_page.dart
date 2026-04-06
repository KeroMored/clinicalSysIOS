import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../data/models/gym_model.dart';
import 'edit_gym_screen.dart';
import 'gym_details_screen.dart';
import 'gym_content_management_screen.dart';
import 'send_gym_notification_screen.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class GymControlPage extends StatefulWidget {
  final String gymEmail;

  const GymControlPage({super.key, required this.gymEmail});

  @override
  State<GymControlPage> createState() => _GymControlPageState();
}

class _GymControlPageState extends State<GymControlPage> {
  GymModel? _gym;
  bool _isLoading = true;

  PreferredSizeWidget _buildControlAppBar(String title) {
    return GradientAppBar(
      title: title,
      gradient: AppTheme.gymGradient,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            )
          : null,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadGymData();
  }

  Future<void> _loadGymData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('gyms')
          .where('authEmails', arrayContains: widget.gymEmail)
          .where('isApproved', isEqualTo: true)
          .limit(1)
          .get();

      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _gym = GymModel.fromFirestore(snapshot.docs.first);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في تحميل البيانات: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: AppLoadingIndicator()));
    }

    if (_gym == null) {
      return Scaffold(
        appBar: _buildControlAppBar('لوحة التحكم'),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center, size: 100, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'لا يوجد جيم مسجل بهذا البريد الإلكتروني',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_gym!.isApproved) {
      return Scaffold(
        appBar: _buildControlAppBar('لوحة التحكم'),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.hourglass_empty,
                  size: 100,
                  color: Colors.orange[400],
                ),
                const SizedBox(height: 20),
                Text(
                  'الجيم في انتظار الموافقة من الإدارة',
                  style: TextStyle(fontSize: 18, color: Colors.orange[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildControlAppBar(_gym!.name),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Gym Info Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Logo
                      if (_gym!.logoUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _gym!.logoUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.fitness_center,
                                    size: 50,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                          ),
                        )
                      else
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.fitness_center,
                            size: 50,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Gym Name
                      Text(
                        _gym!.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Description
                      if (_gym!.description.isNotEmpty)
                        Text(
                          _gym!.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 16),

                      // Phone
                      _buildInfoRow(Icons.phone, 'الهاتف', _gym!.phone),
                      const SizedBox(height: 12),

                      // WhatsApp
                      _buildInfoRow(
                        MdiIcons.whatsapp,
                        'واتساب',
                        _gym!.whatsapp,
                      ),
                      const SizedBox(height: 12),

                      // Address
                      _buildInfoRow(
                        Icons.location_on,
                        'العنوان',
                        _gym!.address,
                      ),
                      const SizedBox(height: 12),

                      // City & Governorate
                      _buildInfoRow(
                        Icons.location_city,
                        'المدينة',
                        '${_gym!.city}, ${_gym!.governorate}',
                      ),
                      const SizedBox(height: 16),

                      // Sections
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (_gym!.hasMaleSection)
                            _buildFeatureChip(
                              Icons.male,
                              'قسم رجالي',
                              const Color(0xFF3B82F6),
                            ),
                          if (_gym!.hasFemaleSection)
                            _buildFeatureChip(
                              Icons.female,
                              'قسم نسائي',
                              const Color(0xFFEC4899),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.star,
                              value: _gym!.averageRating.toStringAsFixed(1),
                              label: 'التقييم',
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.favorite,
                              value: '${_gym!.totalLikes}',
                              label: 'إعجاب',
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Control Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildControlCard(
                      title: 'تفاصيل الجيم',
                      icon: Icons.public,
                      color: AppTheme.primaryColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GymDetailsScreen(gym: _gym!),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildControlCard(
                      title: 'تعديل بيانات الجيم',
                      icon: Icons.edit,
                      color: AppTheme.primaryColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditGymScreen(gym: _gym!),
                          ),
                        ).then((updated) {
                          if (updated == true) {
                            _loadGymData();
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Second row: content and notifications
              Row(
                children: [
                  Expanded(
                    child: _buildControlCard(
                      title: 'المحتوى والعروض',
                      icon: Icons.photo_library,
                      color: AppTheme.primaryColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                GymContentManagementScreen(gymId: _gym!.id),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildControlCard(
                      title: 'الإشعارات',
                      icon: Icons.notifications_active,
                      color: AppTheme.primaryColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SendGymNotificationScreen(gym: _gym!),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
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
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildControlCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
