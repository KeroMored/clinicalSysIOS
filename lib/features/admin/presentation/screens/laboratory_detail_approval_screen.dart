import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../laboratory/data/models/laboratory_model.dart';
import '../../../laboratory/data/models/working_hours.dart';
import '../../presentation/cubit/admin_cubit.dart';
import '../../presentation/cubit/admin_state.dart';

class LaboratoryDetailApprovalScreen extends StatelessWidget {
  final LaboratoryModel laboratory;

  const LaboratoryDetailApprovalScreen({Key? key, required this.laboratory})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (laboratory.status) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'مقبول';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'مرفوض';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'قيد الانتظار';
        statusIcon = Icons.access_time;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المعمل'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state is RequestApproved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is RequestRejected) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.pop(context);
          } else if (state is RequestSetToPending) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.orange,
              ),
            );
            Navigator.pop(context);
          } else if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('حدث خطأ: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with status
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1)),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 3),
                      ),
                      child: laboratory.logoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                laboratory.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.science,
                                  color: Colors.green,
                                  size: 50,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.science,
                              color: Colors.green,
                              size: 50,
                            ),
                    ),
                    const SizedBox(height: 12),

                    // Laboratory name
                    Text(
                      laboratory.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Created date
                    Text(
                      'تاريخ الطلب: ${DateFormat('yyyy/MM/dd - hh:mm a').format(laboratory.createdAt)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),

              // Details section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Owner Information
                    _buildSectionTitle('بيانات المالك'),
                    _buildInfoCard([
                      _buildDetailRow(
                        Icons.person,
                        'اسم المالك',
                        laboratory.ownerName,
                      ),
                      const SizedBox(height: 12),
                      // Contact Buttons
                      Row(
                        children: [
                          // Call Button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _makePhoneCall(laboratory.ownerPhone),
                              icon: const Icon(Icons.phone),
                              label: const Text('اتصال'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // WhatsApp Button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _openWhatsApp(laboratory.ownerPhone),
                              icon: Icon(FontAwesomeIcons.whatsapp),
                              label: const Text('واتساب'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // Laboratory Information
                    _buildSectionTitle('معلومات المعمل'),
                    _buildInfoCard([
                      _buildDetailRow(
                        Icons.location_on,
                        'العنوان',
                        laboratory.address,
                      ),
                      if (laboratory.description != null &&
                          laboratory.description!.isNotEmpty)
                        _buildDetailRow(
                          Icons.description,
                          'الوصف',
                          laboratory.description!,
                        ),
                    ]),

                    const SizedBox(height: 16),

                    // Available Tests
                    _buildSectionTitle(
                      'التحاليل المتاحة (${laboratory.availableTests.length})',
                    ),
                    _buildInfoCard([
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: laboratory.availableTests.map((test) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade400,
                                  Colors.green.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              test,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // Home Service
                    if (laboratory.hasHomeService) ...[
                      _buildSectionTitle('الخدمة المنزلية'),
                      _buildInfoCard([
                        Row(
                          children: [
                            const Icon(
                              Icons.home,
                              size: 24,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'خدمة منزلية متاحة',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (laboratory.homeServiceFee != null)
                                    Text(
                                      'السعر: ${laboratory.homeServiceFee} جنيه',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 16),
                    ],

                    // Certifications

                    // Working Hours
                    _buildSectionTitle('مواعيد العمل'),
                    _buildInfoCard([
                      _buildWorkingHours(laboratory.workingHours),
                    ]),

                    // Rejection Reason (if rejected)
                    if (laboratory.status == 'rejected' &&
                        laboratory.rejectionReason != null) ...[
                      const SizedBox(height: 16),
                      _buildSectionTitle('سبب الرفض'),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info, color: Colors.red, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                laboratory.rejectionReason!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 80), // Space for action buttons
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Action Buttons (fixed at bottom)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: _buildActionButtons(context, laboratory),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingHours(Map<String, WorkingHours> workingHours) {
    final days = [
      {'key': 'saturday', 'name': 'السبت'},
      {'key': 'sunday', 'name': 'الأحد'},
      {'key': 'monday', 'name': 'الإثنين'},
      {'key': 'tuesday', 'name': 'الثلاثاء'},
      {'key': 'wednesday', 'name': 'الأربعاء'},
      {'key': 'thursday', 'name': 'الخميس'},
      {'key': 'friday', 'name': 'الجمعة'},
    ];

    return Column(
      children: days.map((day) {
        final dayData = workingHours[day['key']];
        final isAvailable = dayData != null ? !dayData.isHoliday : false;
        final from = dayData?.openTime ?? 'غير محدد';
        final to = dayData?.closeTime ?? 'غير محدد';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  day['name']!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green[50] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAvailable
                          ? Colors.green[300]!
                          : Colors.grey[400]!,
                    ),
                  ),
                  child: Text(
                    isAvailable ? '$from - $to' : 'عطلة',
                    style: TextStyle(
                      fontSize: 13,
                      color: isAvailable ? Colors.green[800] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(BuildContext context, LaboratoryModel lab) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // Approve Button (if pending)
            if (lab.status == 'pending')
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showApproveDialog(context, lab.id);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('قبول المعمل'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

            // Back to Pending (if approved)
            if (lab.status == 'approved')
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showBackToPendingDialog(context, lab.id);
                  },
                  icon: const Icon(Icons.undo),
                  label: const Text('إرجاع للانتظار'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

            if (lab.status == 'pending' || lab.status == 'approved')
              const SizedBox(width: 12),

            // Reject Button (if pending)
            if (lab.status == 'pending')
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showRejectDialog(context, lab.id);
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text('رفض المعمل'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Delete Button (always available)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _showDeleteDialog(context, lab.id, lab.name);
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text('حذف المعمل نهائياً'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showApproveDialog(BuildContext context, String labId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد القبول'),
        content: const Text('هل أنت متأكد من قبول هذا المعمل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AdminCubit>().approveLaboratoryRequest(labId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String labId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض المعمل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('الرجاء إدخال سبب الرفض:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'سبب الرفض...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرجاء إدخال سبب الرفض'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              context.read<AdminCubit>().rejectLaboratoryRequest(
                labId,
                reasonController.text.trim(),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }

  void _showBackToPendingDialog(BuildContext context, String labId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إرجاع للانتظار'),
        content: const Text('هل تريد إرجاع هذا المعمل لحالة الانتظار؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AdminCubit>().backLaboratoryToPending(labId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('إرجاع'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String labId, String labName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المعمل'),
        content: Text('هل أنت متأكد من حذف "$labName" نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AdminCubit>().deleteLaboratory(labId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  String _formatWhatsAppNumber(String input) {
    // Keep digits and '+' only initially
    String n = input.trim();
    // Remove all spaces, dashes, and parentheses
    n = n.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Remove leading '+'
    if (n.startsWith('+')) n = n.substring(1);
    // Convert leading '00' international prefix to just country code
    if (n.startsWith('00')) n = n.substring(2);
    // Remove a single leading '0' for local numbers as requested
    if (n.startsWith('0')) n = n.substring(1);
    // Finally, strip any remaining non-digits to be safe
    n = n.replaceAll(RegExp(r'[^0-9]'), '');
    return n;
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      // Silently fail or show error if needed
    }
  }

  void _openWhatsApp(String phoneNumber) async {
    final formatted = _formatWhatsAppNumber(phoneNumber);
    if (formatted.isEmpty) return;

    final String whatsappUrl = "https://wa.me/$formatted";
    try {
      await launchUrl(Uri.parse(whatsappUrl));
    } catch (e) {
      // Silently fail or show error if needed
    }
  }
}
