import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/medicine_request_model.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class MyMedicineRequestsScreen extends StatelessWidget {
  const MyMedicineRequestsScreen({super.key});

  static const Color _brandColor = Color(0xFF0B8293);
  static const Color _brandColorDark = Color(0xFF0A6F7C);
  static const Color _pageBackground = Color(0xFFF4F6F8);

  Future<void> _markAsCompleted(BuildContext context, String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('medicine_requests')
          .doc(requestId)
          .update({
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
          });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث الطلب بنجاح ✓'),
            backgroundColor: _brandColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteRequest(BuildContext context, String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('medicine_requests')
          .doc(requestId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الطلب بنجاح'),
            backgroundColor: Color(0xFF64748B),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCompletionDialog(BuildContext context, String requestId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد التواصل'),
        content: const Text(
          'هل تم التواصل معك من إحدى الصيدليات؟\n'
          'سيتم إخفاء الطلب من باقي الصيدليات.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _markAsCompleted(context, requestId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('نعم، تم التواصل'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String requestId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الطلب'),
        content: const Text('هل أنت متأكد من حذف هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteRequest(context, requestId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;

    if (authState is! Authenticated) {
      return Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _brandColor),
          title: const Text(
            'طلباتي',
            style: TextStyle(color: _brandColor, fontWeight: FontWeight.w700),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
        ),
        body: const Center(child: Text('يجب تسجيل الدخول لعرض طلباتك')),
      );
    }

    final userId = authState.user.uid;

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _brandColor),
        title: const Text(
          'طلباتي',
          style: TextStyle(color: _brandColor, fontWeight: FontWeight.w700),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('medicine_requests')
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'pending')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 50,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'حدث خطأ في تحميل الطلبات',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: AppLoadingIndicator(color: _brandColor),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ليس لديك طلبات حالياً',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اطلب دواءك وسيظهر هنا',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              );
            }

            final requests = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final requestDoc = requests[index];
                final requestData = requestDoc.data() as Map<String, dynamic>;
                final request = MedicineRequestModel.fromJson({
                  'id': requestDoc.id,
                  ...requestData,
                });

                return _buildRequestCard(context, request);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, MedicineRequestModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_brandColor, _brandColorDark],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.medication,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    request.allMedicines.length == 1
                        ? request.allMedicines[0].medicineName
                        : 'طلب ${request.allMedicines.length} أدوية',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC6E7EC)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pending, size: 14, color: _brandColorDark),
                      SizedBox(width: 4),
                      Text(
                        'قيد الانتظار',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _brandColorDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.list_alt, size: 16, color: _brandColor),
                      SizedBox(width: 6),
                      Text(
                        'الأدوية المطلوبة',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...request.allMedicines.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final med = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 7),
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_brandColor, _brandColorDark],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.medicineName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                if (med.medicineType != null)
                                  Text(
                                    med.medicineType!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  '${med.quantity} ${med.quantityUnit ?? "علبة"}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF334155),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (med.imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                med.imageUrl!,
                                width: 54,
                                height: 54,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 54,
                                    height: 54,
                                    color: const Color(0xFFE2E8F0),
                                    child: const Icon(Icons.image, size: 20),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const Divider(height: 22),
            _buildInfoRow(
              icon: Icons.phone,
              label: 'رقم الهاتف',
              value: request.phoneNumber,
              color: _brandColor,
            ),
            if (request.whatsappNumber != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.chat_bubble,
                label: 'واتساب',
                value: request.whatsappNumber!,
                color: const Color(0xFF25D366),
              ),
            ],
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.access_time,
              label: 'تاريخ الطلب',
              value: _formatDate(request.createdAt),
              color: _brandColorDark,
            ),
            if (request.notes != null && request.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCFE5EA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note, size: 18, color: _brandColor),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        request.notes!,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_brandColor, _brandColorDark],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _brandColor.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showCompletionDialog(context, request.id),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('تم التواصل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeleteDialog(context, request.id),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('حذف'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: const Color(0xFFFFF5F5),
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'الآن';
        }
        return 'منذ ${difference.inMinutes} دقيقة';
      }
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays == 1) {
      return 'أمس ${DateFormat('hh:mm a').format(date)}';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return DateFormat('yyyy-MM-dd hh:mm a').format(date);
    }
  }
}
