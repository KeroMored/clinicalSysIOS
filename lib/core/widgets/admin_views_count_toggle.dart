import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/app_control_service.dart';
import 'package:mallawicure/core/widgets/app_loading_indicator.dart';

/// ويدجت للأدمن للتحكم السريع في عرض عدد المشاهدات
/// يظهر كـ FAB أو IconButton في شاشات العروض
class AdminViewsCountToggle extends StatefulWidget {
  /// نوع العرض: 'fab' أو 'icon'
  final String displayType;

  const AdminViewsCountToggle({super.key, this.displayType = 'icon'});

  @override
  State<AdminViewsCountToggle> createState() => _AdminViewsCountToggleState();
}

class _AdminViewsCountToggleState extends State<AdminViewsCountToggle> {
  final AppControlService _controlService = AppControlService();
  final List<String> _adminEmails = [
    'admin@clinicalsystem.com',
    'kerolesmored@gmail.com',
  ];

  bool _isAdmin = false;
  bool _isLoading = true;
  bool _showViewsCount = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoadSettings();
  }

  Future<void> _checkAdminAndLoadSettings() async {
    // التحقق من أن المستخدم أدمن
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isAdmin = false;
        _isLoading = false;
      });
      return;
    }

    final isAdmin = _adminEmails.contains(user.email?.toLowerCase());

    if (!isAdmin) {
      setState(() {
        _isAdmin = false;
        _isLoading = false;
      });
      return;
    }

    // تحميل الإعدادات الحالية
    try {
      final settings = await _controlService.getOffersSettings();
      if (mounted) {
        setState(() {
          _isAdmin = true;
          _showViewsCount = settings.showViewsCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdmin = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleViewsCount() async {
    final newValue = !_showViewsCount;

    // إظهار loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: AppLoadingIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );

    try {
      await _controlService.updateShowViewsCount(newValue);

      if (mounted) {
        Navigator.of(context).pop(); // إغلاق loading dialog

        setState(() {
          _showViewsCount = newValue;
        });

        // إظهار رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    newValue
                        ? '✅ تم تفعيل عرض عدد المشاهدات في جميع الشاشات'
                        : '✅ تم إخفاء عدد المشاهدات من جميع الشاشات',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // إغلاق loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('خطأ: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showToggleDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFF00BCD4),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'إعدادات الأدمن',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'التحكم في عرض عدد المشاهدات لجميع المستخدمين',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _showViewsCount
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _showViewsCount
                        ? Colors.green.shade300
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _showViewsCount ? Icons.visibility : Icons.visibility_off,
                      color: _showViewsCount ? Colors.green : Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _showViewsCount
                                ? 'عرض المشاهدات مُفعّل'
                                : 'عرض المشاهدات مُعطّل',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _showViewsCount
                                  ? Colors.green
                                  : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _showViewsCount
                                ? 'المستخدمون يرون عدد المشاهدات'
                                : 'عدد المشاهدات مخفي عن المستخدمين',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _toggleViewsCount();
              },
              icon: Icon(
                _showViewsCount ? Icons.visibility_off : Icons.visibility,
              ),
              label: Text(_showViewsCount ? 'إخفاء العدد' : 'إظهار العدد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // إخفاء الويدجت إذا لم يكن المستخدم أدمن
    if (!_isAdmin || _isLoading) {
      return const SizedBox.shrink();
    }

    // عرض FAB أو IconButton حسب النوع
    if (widget.displayType == 'fab') {
      return FloatingActionButton(
        mini: true,
        backgroundColor: const Color(0xFF00BCD4),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              _showViewsCount ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
              size: 20,
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _showViewsCount ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
          ],
        ),
        onPressed: _showToggleDialog,
      );
    }

    // IconButton (default)
    return IconButton(
      icon: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            _showViewsCount ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _showViewsCount ? Colors.green : Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
        ],
      ),
      tooltip: _showViewsCount
          ? 'إخفاء عدد المشاهدات (مُفعّل حالياً)'
          : 'إظهار عدد المشاهدات (مُعطّل حالياً)',
      onPressed: _showToggleDialog,
    );
  }
}
