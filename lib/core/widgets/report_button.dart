import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/report_service.dart';
import '../utils/auth_helpers.dart';

class ReportButton extends StatelessWidget {
  final String serviceId;
  final String serviceType;
  final String serviceName;
  final double iconSize;
  final bool showLabel;

  const ReportButton({
    Key? key,
    required this.serviceId,
    required this.serviceType,
    required this.serviceName,
    this.iconSize = 24.0,
    this.showLabel = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showReportDialog(context),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flag_outlined,
              color: Colors.grey[600],
              size: iconSize,
            ),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                'إبلاغ',
                style: TextStyle(
                  fontSize: iconSize * 0.7,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) async {
    // Check authentication first
    final isAuthenticated = await AuthHelpers.requireAuth(
      context,
      message: 'يجب تسجيل الدخول للإبلاغ عن المكان',
    );
    
    if (!isAuthenticated) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String complaint = '';
    String selectedReason = 'معلومات خاطئة';
    final List<String> reasons = [
      'معلومات خاطئة',
      'رقم هاتف خاطئ',
      'عنوان خاطئ',
      'الخدمة غير متوفرة',
      'سوء معاملة',
      'أسعار مبالغ فيها',
      'غير متخصص',
      'أخرى',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.flag,
                  color: Colors.red[700],
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'إبلاغ عن مشكلة',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الخدمة: $serviceName',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'نوع المشكلة',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedReason,
                        isExpanded: true,
                        items: reasons.map((String reason) {
                          return DropdownMenuItem<String>(
                            value: reason,
                            child: Text(reason),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedReason = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تفاصيل المشكلة',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    maxLines: 4,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'اكتب تفاصيل المشكلة هنا...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (value) {
                      complaint = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ملاحظة: سيتم مراجعة البلاغ من قبل الإدارة',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: complaint.trim().isEmpty
                    ? null
                    : () async {
                        try {
                          final reportService = ReportService();
                          final fullComplaint = '$selectedReason: $complaint';

                          await reportService.submitReport(
                            serviceId: serviceId,
                            serviceType: serviceType,
                            serviceName: serviceName,
                            userId: user.uid,
                            userEmail: user.email ?? '',
                            userName: user.displayName ?? 'مستخدم',
                            complaint: fullComplaint,
                          );

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم إرسال البلاغ بنجاح. شكراً لمساعدتنا'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('حدث خطأ: $e')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('إرسال البلاغ'),
              ),
            ],
          );
        },
      ),
    );
  }
}
