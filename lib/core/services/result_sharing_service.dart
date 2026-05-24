import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import '../../features/laboratory/data/models/lab_result_model.dart';

/// خدمة مشاركة نتائج التحاليل
class ResultSharingService {
  /// مشاركة النتيجة عبر WhatsApp
  static Future<void> shareViaWhatsApp(
    LabResultModel result, {
    String? phoneNumber,
  }) async {
    final message =
        '''
🔬 *نتيجة تحليل ${result.testName}*

📋 رقم النتيجة: ${result.id.substring(0, 8)}
📅 التاريخ: ${_formatDate(result.uploadedAt)}
🏥 المعمل: ${result.laboratoryName}

📎 رابط النتيجة: ${result.pdfUrl}

*ملحوظة:* النتيجة متاحة للعرض والتحميل من الرابط أعلاه
    ''';

    String url;
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      // إرسال لرقم محدد
      url = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
    } else {
      // فتح قائمة جهات الاتصال
      url = 'https://wa.me/?text=${Uri.encodeComponent(message)}';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('لا يمكن فتح WhatsApp');
    }
  }

  /// مشاركة النتيجة عبر Email
  static Future<void> shareViaEmail(
    LabResultModel result, {
    String? recipientEmail,
    String? doctorName,
  }) async {
    final subject = 'نتيجة تحليل ${result.testName}';
    final body =
        '''
<div dir="rtl" style="font-family: Arial, sans-serif;">
  <h2 style="color: #00BCD4;">🔬 نتيجة تحليل ${result.testName}</h2>
  
  <p><strong>اسم المريض:</strong> ${result.patientName}</p>
  <p><strong>رقم النتيجة:</strong> ${result.id.substring(0, 8)}</p>
  <p><strong>تاريخ التحليل:</strong> ${_formatDate(result.uploadedAt)}</p>
  <p><strong>المعمل:</strong> ${result.laboratoryName}</p>
  ${doctorName != null ? '<p><strong>الطبيب المعالج:</strong> $doctorName</p>' : ''}
  
  <hr style="border-color: #E0E0E0;">
  
  <p><strong>لعرض النتيجة الكاملة:</strong></p>
  <a href="${result.pdfUrl}" 
     style="display: inline-block; padding: 12px 24px; background: linear-gradient(135deg, #00BCD4 0%, #1E3A5F 100%); 
            color: white; text-decoration: none; border-radius: 8px; margin: 10px 0;">
    📄 عرض النتيجة (PDF)
  </a>
  
  <p style="color: #666; font-size: 12px; margin-top: 20px;">
    هذه النتيجة تم إرسالها من نظام إدارة المعامل. يُرجى عدم الرد على هذا البريد الإلكتروني.
  </p>
</div>
    ''';

    final emailUri = Uri(
      scheme: 'mailto',
      path: recipientEmail ?? '',
      query: {'subject': subject, 'body': body}.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&'),
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw Exception('لا يمكن فتح تطبيق البريد الإلكتروني');
    }
  }

  /// مشاركة عامة (خيارات متعددة)
  static Future<void> shareGeneral(LabResultModel result) async {
    final message =
        '''
🔬 نتيجة تحليل ${result.testName}

📋 رقم النتيجة: ${result.id.substring(0, 8)}
📅 التاريخ: ${_formatDate(result.uploadedAt)}
🏥 المعمل: ${result.laboratoryName}

📎 رابط النتيجة:
${result.pdfUrl}
    ''';

    await Share.share(message, subject: 'نتيجة تحليل ${result.testName}');
  }

  /// توليد QR Code للنتيجة
  static Widget generateQRCode(LabResultModel result, {double size = 200}) {
    final data = {
      'type': 'lab_result',
      'resultId': result.id,
      'testName': result.testName,
      'patientName': result.patientName,
      'laboratoryName': result.laboratoryName,
      'uploadedAt': result.uploadedAt.toIso8601String(),
      'pdfUrl': result.pdfUrl,
    };

    return QrImageView(
      data: Uri(
        scheme: 'clinicalsystem',
        host: 'labresult',
        queryParameters: data,
      ).toString(),
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF00BCD4),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF1E3A5F),
      ),
      embeddedImage: AssetImage('assets/images/lab_icon.png'),
      embeddedImageStyle: QrEmbeddedImageStyle(size: Size(40, 40)),
    );
  }

  /// فتح النتيجة في المتصفح
  static Future<void> openInBrowser(LabResultModel result) async {
    if (result.pdfUrl == null || result.pdfUrl!.isEmpty) {
      throw Exception('لا يوجد ملف PDF');
    }
    final uri = Uri.parse(result.pdfUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('لا يمكن فتح الرابط');
    }
  }

  /// تنسيق التاريخ
  static String _formatDate(DateTime date) {
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// عرض dialog المشاركة
  static void showShareDialog(BuildContext context, LabResultModel result) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'مشاركة النتيجة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareButton(
                  icon: Icons.chat, // WhatsApp icon
                  label: 'WhatsApp',
                  color: Color(0xFF25D366),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await shareViaWhatsApp(result);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطأ: ${e.toString()}')),
                      );
                    }
                  },
                ),
                _ShareButton(
                  icon: Icons.email,
                  label: 'Email',
                  color: Color(0xFFEA4335),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await shareViaEmail(result);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطأ: ${e.toString()}')),
                      );
                    }
                  },
                ),
                _ShareButton(
                  icon: Icons.qr_code,
                  label: 'QR Code',
                  color: Color(0xFF00BCD4),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('امسح الكود للوصول للنتيجة'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            generateQRCode(result),
                            SizedBox(height: 16),
                            Text(
                              'رقم النتيجة: ${result.id.substring(0, 8)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('إغلاق'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                _ShareButton(
                  icon: Icons.share,
                  label: 'المزيد',
                  color: Color(0xFF1E3A5F),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await shareGeneral(result);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطأ: ${e.toString()}')),
                      );
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// زر المشاركة
class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
