import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../../../core/services/app_control_service.dart';
import 'package:mallawycare/core/widgets/app_loading_indicator.dart';

/// صفحة إدارة إعدادات العروض
/// تتيح للمشرفين التحكم في إظهار/إخفاء عدد المشاهدات
class OffersSettingsScreen extends StatefulWidget {
  const OffersSettingsScreen({super.key});

  @override
  State<OffersSettingsScreen> createState() => _OffersSettingsScreenState();
}

class _OffersSettingsScreenState extends State<OffersSettingsScreen> {
  final AppControlService _controlService = AppControlService();
  bool _isLoading = true;
  bool _showViewsCount = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final settings = await _controlService.getOffersSettings();
      if (mounted) {
        setState(() {
          _showViewsCount = settings.showViewsCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الإعدادات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings(bool newValue) async {
    setState(() => _isSaving = true);

    try {
      await _controlService.updateShowViewsCount(newValue);

      if (mounted) {
        setState(() {
          _showViewsCount = newValue;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newValue
                  ? '✅ تم تفعيل عرض عدد المشاهدات'
                  : '✅ تم إخفاء عدد المشاهدات',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحفظ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initializeSettings() async {
    setState(() => _isSaving = true);

    try {
      await _controlService.initializeOffersSettings();
      await _loadSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إنشاء الإعدادات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: GradientAppBar(
          title: 'إعدادات العروض',
          gradient: AppTheme.primaryGradient,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
            ),
          ),
          child: _isLoading
              ? const Center(
                  child: AppLoadingIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // بطاقة معلومات
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF00BCD4,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.settings_outlined,
                                  size: 48,
                                  color: Color(0xFF00BCD4),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'التحكم في إعدادات العروض',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A5F),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'يمكنك إظهار أو إخفاء عدد المشاهدات في جميع شاشات العروض',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // بطاقة الإعداد الرئيسي
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.visibility_outlined,
                                    color: _showViewsCount
                                        ? const Color(0xFF00BCD4)
                                        : Colors.grey,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'عرض عدد المشاهدات',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E3A5F),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _showViewsCount
                                              ? 'مُفعّل - المستخدمون يرون عدد المشاهدات'
                                              : 'غير مُفعّل - عدد المشاهدات مخفي',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _showViewsCount,
                                    onChanged: _isSaving ? null : _saveSettings,
                                    activeColor: const Color(0xFF00BCD4),
                                  ),
                                ],
                              ),

                              const Divider(height: 32),

                              // معلومات إضافية
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'عدد المشاهدات يُحفظ دائماً في قاعدة البيانات، هذا الإعداد يتحكم فقط في عرضه للمستخدمين',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // بطاقة التأثير
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.apps,
                                    color: Color(0xFF00BCD4),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'الشاشات المتأثرة',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E3A5F),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildAffectedScreen(
                                icon: Icons.local_offer,
                                title: 'عروض الأدوية',
                                description: 'Medicine Offers Screen',
                              ),
                              const Divider(height: 20),
                              _buildAffectedScreen(
                                icon: Icons.local_pharmacy,
                                title: 'عروض الصيدلية الواحدة',
                                description: 'Pharmacy Offers List',
                              ),
                              const Divider(height: 20),
                              _buildAffectedScreen(
                                icon: Icons.discount,
                                title: 'جميع العروض',
                                description: 'All Offers Screen',
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // زر إعادة تهيئة الإعدادات
                      OutlinedButton.icon(
                        onPressed: _isSaving ? null : _initializeSettings,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة تهيئة الإعدادات'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00BCD4),
                          side: const BorderSide(color: Color(0xFF00BCD4)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'استخدم هذا الزر إذا كانت الإعدادات غير موجودة في قاعدة البيانات',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAffectedScreen({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00BCD4).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF00BCD4), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const Icon(Icons.check_circle, color: Colors.green, size: 20),
      ],
    );
  }
}
