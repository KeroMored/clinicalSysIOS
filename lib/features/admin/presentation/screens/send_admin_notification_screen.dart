import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import 'package:mallawicure/core/widgets/app_loading_indicator.dart';

class SendAdminNotificationScreen extends StatefulWidget {
  const SendAdminNotificationScreen({super.key});

  @override
  State<SendAdminNotificationScreen> createState() =>
      _SendAdminNotificationScreenState();
}

class _SendAdminNotificationScreenState
    extends State<SendAdminNotificationScreen> {
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.mored.mallawycare&pcampaignid=web_share';

  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();

  bool _openStoreOnTap = true;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _openPlayStore() async {
    final uri = Uri.parse(_playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد إرسال الإشعار'),
        content: const Text(
          'سيتم إرسال الإشعار لجميع مستخدمي التطبيق. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSending = true);

    try {
      await FirebaseFirestore.instance
          .collection('admin_notifications_broadcast')
          .add({
            'title': 'ملوي كيور | Mallawi Cure',
            'message': _messageController.text.trim(),
            'topic': 'all_users',
            'openStoreOnTap': _openStoreOnTap,
            'openUrl': _openStoreOnTap ? _playStoreUrl : '',
            'createdAt': FieldValue.serverTimestamp(),
            'sent': false,
          });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم إرسال الإشعار لجميع المستخدمين بنجاح'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إرسال الإشعار: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إرسال إشعار عام',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: AppTheme.primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF7DD3FC)),
                  ),
                  child: const Text(
                    'اسم المرسل في الإشعار سيكون: ملوي كيور | Mallawi Cure',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0C4A6E),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 300,
                  decoration: InputDecoration(
                    labelText: 'نص الإشعار',
                    hintText:
                        'مثال: يوجد تحديث جديد للتطبيق، حدّث الآن من متجر Google Play',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'اكتب نص الإشعار';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  value: _openStoreOnTap,
                  activeColor: AppTheme.primaryColor,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'فتح التطبيق في المتجر عند الضغط على الإشعار',
                  ),
                  subtitle: const Text('Google Play - ملوي كيور | Mallawi Cure'),
                  onChanged: (value) => setState(() => _openStoreOnTap = value),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _openPlayStore,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('فتح صفحة التطبيق في المتجر الآن'),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendNotification,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: AppLoadingIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    label: Text(
                      _isSending ? 'جاري الإرسال...' : 'إرسال الإشعار',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
