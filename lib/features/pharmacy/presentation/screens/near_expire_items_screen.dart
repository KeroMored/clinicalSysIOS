import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/near_expire_item_model.dart';
import 'edit_near_expire_item_screen.dart';
import 'pharmacy_details_screen.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class NearExpireItemsScreen extends StatefulWidget {
  const NearExpireItemsScreen({super.key});

  @override
  State<NearExpireItemsScreen> createState() => _NearExpireItemsScreenState();
}

class _NearExpireItemsScreenState extends State<NearExpireItemsScreen> {
  static const Color _primary = Color(0xFF0B8293);
  static const Color _primaryDark = Color(0xFF0A6F7C);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F8),
        surfaceTintColor: const Color(0xFFF4F6F8),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 20, color: _primary),
        ),
        title: const Text(
          'أدوية قاربت على الانتهاء',
          style: TextStyle(
            color: _primary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4F6F8), Color(0xFFF1F5F9)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('near_expire_items')
              .where('isActive', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .limit(50) // عرض آخر 50 منتج
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('حدث خطأ: ${snapshot.error}'),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: AppLoadingIndicator(color: _primary));
            }

            final items = snapshot.data!.docs
                .map((doc) => NearExpireItemModel.fromFirestore(doc))
                .toList();

            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد أدوية معروضة حالياً',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _NearExpireItemCard(item: items[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _NearExpireItemCard extends StatelessWidget {
  static const Color _primary = Color(0xFF0B8293);
  static const Color _primaryDark = Color(0xFF0A6F7C);

  final NearExpireItemModel item;

  const _NearExpireItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final isOwner =
        authState is Authenticated && authState.user.uid == item.userId;
    final daysLeft = item.daysUntilExpiry;
    final urgencyColor = daysLeft <= 30
        ? Colors.red
        : (daysLeft <= 60 ? const Color(0xFFF59E0B) : const Color(0xFF0B8293));

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة المنتج (إن وجدت) مع زر القائمة
          if (item.imageUrl != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    item.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.medical_services,
                          size: 80,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                // زر القائمة (فقط لصاحب البوست)
                if (isOwner)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: _primary),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editItem(context, item);
                          } else if (value == 'delete') {
                            _confirmDelete(context, item);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: _primary, size: 20),
                                SizedBox(width: 8),
                                Text('تعديل'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'حذف',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // اسم الدواء مع زر القائمة (إذا لم تكن هناك صورة)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.medicineName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isOwner && item.imageUrl == null)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: _primary),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editItem(context, item);
                          } else if (value == 'delete') {
                            _confirmDelete(context, item);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: _primary, size: 20),
                                SizedBox(width: 8),
                                Text('تعديل'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'حذف',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 4),

                // نوع الدواء
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.medicineType,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // الوصف
                if (item.medicineDescription != null &&
                    item.medicineDescription!.isNotEmpty) ...[
                  Text(
                    item.medicineDescription!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                ],

                // معلومات الانتهاء
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: urgencyColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: urgencyColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ينتهي في ${item.monthsUntilExpiry} شهر',
                        style: TextStyle(
                          color: urgencyColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${item.expiryDate.year}/${item.expiryDate.month}',
                        style: TextStyle(color: urgencyColor, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // الكمية وسعر العبوة
                Row(
                  children: [
                    // الكمية
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الكمية المتاحة',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.quantity} عبوة',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // سعر العبوة
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFEFF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'سعر العبوة',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.unitPrice != null
                                  ? '${item.unitPrice!.toStringAsFixed(2)} ج'
                                  : 'غير محدد',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: item.unitPrice != null
                                    ? _primary
                                    : Colors.grey,
                              ),
                            ),
                            if (item.totalPrice != null)
                              Text(
                                'إجمالي: ${item.totalPrice!.toStringAsFixed(2)} ج',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: _primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // معلومات الصيدلية
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'معلومات الصيدلية',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),

                // اسم الصيدلية (قابل للنقر)
                GestureDetector(
                  onTap: () => _openPharmacyDetails(context, item.pharmacyId),
                  child: Row(
                    children: [
                      const Icon(Icons.store, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.pharmacyName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _primaryDark,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: _primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                _buildInfoRow(Icons.location_on, item.pharmacyAddress),
                const SizedBox(height: 12),

                // أزرار التواصل
                Row(
                  children: [
                    if (item.pharmacyPhones.isNotEmpty)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _makePhoneCall(
                            context,
                            item.pharmacyPhones.first,
                          ),
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text('اتصال'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _openWhatsApp(context, item.pharmacyWhatsapp),
                        icon: Icon(FontAwesomeIcons.whatsapp, size: 18),
                        label: const Text('واتساب'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // تاريخ ووقت النشر
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'تم النشر: ${_formatDateTime(item.createdAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'الآن';
        }
        return 'منذ ${difference.inMinutes} دقيقة';
      }
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays == 1) {
      return 'أمس ${DateFormat('hh:mm a', 'ar').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(dateTime);
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  void _makePhoneCall(BuildContext context, String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن إجراء المكالمة')));
      }
    }
  }

  String _formatWhatsAppNumber(String input) {
    // خد الرقم زي ما هو وضيفله +20 فقط
    String n = input.trim();
    // لو بيبدأ بـ + شيله
    if (n.startsWith('+')) n = n.substring(1);
    // لو بيبدأ بـ 20 يبقى خلاص
    if (n.startsWith('20')) return '20$n';
    // ضيف +20 قدام الرقم
    return '20$n';
  }

  void _openWhatsApp(BuildContext context, String phoneNumber) async {
    final formatted = _formatWhatsAppNumber(phoneNumber);
    if (formatted.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('رقم واتساب غير صحيح')));
      }
      return;
    }
    final String whatsappUrl = "https://wa.me/$formatted";
    try {
      bool launched = await launchUrl(Uri.parse(whatsappUrl));
      if (!launched) {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح واتساب')));
      }
    }
  }

  void _openPharmacyDetails(BuildContext context, String pharmacyId) async {
    try {
      // استخدام PharmacyCubit الموجود بالفعل أو إنشاء واحد جديد
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PharmacyDetailsScreen(pharmacyId: pharmacyId),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, NearExpireItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${item.medicineName}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteItem(context, item);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(
    BuildContext context,
    NearExpireItemModel item,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('near_expire_items')
          .doc(item.id)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الحذف بنجاح'),
            backgroundColor: Colors.green,
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

  void _editItem(BuildContext context, NearExpireItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNearExpireItemScreen(item: item),
      ),
    );
  }
}
