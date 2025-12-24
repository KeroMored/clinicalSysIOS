import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/pharmacy_request_model.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';

class PharmacyRequestDetailsScreen extends StatelessWidget {
  final PharmacyRequestModel request;

  const PharmacyRequestDetailsScreen({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state is RequestApproved) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is RequestRejected) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.orange,
              ),
            );
          } else if (state is RequestSetToPending) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.blue,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Images Gallery
              if (request.images.isNotEmpty)
                SizedBox(
                  height: 250,
                  child: PageView.builder(
                    itemCount: request.images.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        request.images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image_not_supported, size: 50),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pharmacy Name
                    Text(
                      request.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Badge
                    _buildStatusBadge(request.status),
                    const SizedBox(height: 24),

                    // Owner Information Section
                    _buildSectionTitle('معلومات المالك'),
                    _buildInfoRow(
                        Icons.person, 'الاسم', request.ownerName),
                    _buildInfoRow(
                        Icons.phone, 'رقم الهاتف', request.ownerPhone),
                    const SizedBox(height: 24),

                    // Pharmacy Information
                    _buildSectionTitle('معلومات الصيدلية'),
                    _buildInfoRow(
                        Icons.location_on, 'العنوان', request.address),
                    _buildInfoRow(Icons.phone, 'هاتف الصيدلية', request.phone),
                    _buildInfoRow(
                        MdiIcons.whatsapp, 'واتساب', request.whatsapp),
                    const SizedBox(height: 16),

                    // Working Hours
                    _buildInfoRow(Icons.access_time, 'مواعيد العمل',
                        request.workingHours),
                    _buildInfoRow(
                        Icons.event_busy, 'الإجازات', request.holidays),
                    const SizedBox(height: 24),

                    // Delivery Information
                    _buildSectionTitle('معلومات التوصيل'),
                    _buildInfoRow(
                      Icons.delivery_dining,
                      'خدمة التوصيل',
                      request.hasHomeDelivery ? 'متاحة' : 'غير متاحة',
                    ),
                    if (request.hasHomeDelivery) ...[
                      if (request.deliveryFee != null)
                        _buildInfoRow(Icons.monetization_on, 'رسوم التوصيل',
                            '${request.deliveryFee} جنيه'),
                      if (request.minimumOrderForDelivery != null)
                        _buildInfoRow(
                          Icons.shopping_cart,
                          'الحد الأدنى للطلب',
                          '${request.minimumOrderForDelivery} جنيه',
                        ),
                    ],
                    const SizedBox(height: 24),

                    // Services
                    if (request.services.isNotEmpty) ...[
                      _buildSectionTitle('الخدمات المتوفرة'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: request.services
                            .map((service) => Chip(
                                  label: Text(service),
                                  backgroundColor: Colors.blue.withOpacity(0.1),
                                  labelStyle: const TextStyle(color: Colors.blue),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Location
                    _buildSectionTitle('الموقع'),
                    _buildInfoRow(Icons.location_on, 'خط العرض',
                        request.latitude.toString()),
                    _buildInfoRow(Icons.location_on, 'خط الطول',
                        request.longitude.toString()),
                    ElevatedButton.icon(
                      onPressed: () => _openMap(
                          context, request.latitude, request.longitude),
                      icon: const Icon(Icons.map),
                      label: const Text('عرض على الخريطة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Request Information
                    _buildSectionTitle('معلومات الطلب'),
                    _buildInfoRow(
                      Icons.access_time,
                      'تاريخ الطلب',
                      DateFormat('yyyy-MM-dd hh:mm a')
                          .format(request.requestDate),
                    ),
                    if (request.rejectionReason != null)
                      _buildInfoRow(Icons.cancel, 'سبب الرفض',
                          request.rejectionReason!),
                    const SizedBox(height: 32),

                    // Action Buttons - Show based on current status
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
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
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'في الانتظار';
        icon = Icons.pending;
        break;
      case 'approved':
        color = Colors.green;
        text = 'تمت الموافقة';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        text = 'مرفوض';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = status;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    // Show different buttons based on current status
    return Column(
      children: [
        // Approve Button - show for pending and rejected
        if (request.status != 'approved') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showApproveDialog(context),
              icon: const Icon(Icons.check_circle),
              label: const Text('موافقة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Set to Pending Button - show for approved and rejected
        if (request.status != 'pending') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showSetToPendingDialog(context),
              icon: const Icon(Icons.pending),
              label: const Text('تعيين كـ في الانتظار'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Reject Button - show for pending and approved
        if (request.status != 'rejected') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showRejectDialog(context),
              icon: const Icon(Icons.cancel),
              label: const Text('رفض'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showApproveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الموافقة'),
        content: Text('هل أنت متأكد من الموافقة على صيدلية "${request.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AdminCubit>().approveRequest(request.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('موافقة'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('رفض الطلب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل أنت متأكد من رفض صيدلية "${request.name}"؟'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الرفض',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال سبب الرفض')),
                );
                return;
              }
              Navigator.pop(dialogContext);
              context
                  .read<AdminCubit>()
                  .rejectRequest(request.id, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }

  void _showSetToPendingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعيين كـ في الانتظار'),
        content: Text('هل أنت متأكد من تغيير حالة صيدلية "${request.name}" إلى انتظار؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AdminCubit>().setPendingRequest(request.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('تعيين'),
          ),
        ],
      ),
    );
  }

  Future<void> _openMap(
      BuildContext context, double latitude, double longitude) async {
    final Uri googleMapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح الخريطة')),
        );
      }
    }
  }
}
