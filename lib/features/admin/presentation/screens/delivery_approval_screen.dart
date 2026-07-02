import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../../delivery/data/models/delivery_model.dart';
import '../../../delivery/presentation/cubit/delivery_cubit.dart';
import '../../../delivery/presentation/cubit/delivery_state.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class DeliveryApprovalScreen extends StatefulWidget {
  const DeliveryApprovalScreen({super.key});

  @override
  State<DeliveryApprovalScreen> createState() => _DeliveryApprovalScreenState();
}

class _DeliveryApprovalScreenState extends State<DeliveryApprovalScreen> {
  String _filterStatus = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<DeliveryCubit>().getAllDeliveries();
  }

  List<DeliveryModel> _filterDeliveries(List<DeliveryModel> deliveries) {
    return deliveries.where((delivery) {
      final matchesSearch =
          delivery.deliveryName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          delivery.deliveryPhones.any(
            (phone) => phone.contains(_searchQuery),
          ) ||
          delivery.governorate.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          delivery.city.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _filterStatus == 'all' ||
          (_filterStatus == 'pending' && delivery.status == 'pending') ||
          (_filterStatus == 'approved' && delivery.status == 'approved') ||
          (_filterStatus == 'rejected' && delivery.status == 'rejected');

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _showRejectDialog(String deliveryId) async {
    final TextEditingController reasonController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سبب الرفض'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'أدخل سبب رفض الديليفري',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                context.read<DeliveryCubit>().rejectDelivery(
                  deliveryId,
                  reasonController.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'الموافقة على الديليفري',
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
        child: Column(
          children: [
            // Search and Filter Section
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم أو الهاتف أو العنوان...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Status Filter
                  Row(
                    children: [
                      const Text(
                        'الحالة:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filterStatus,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('الكل')),
                            DropdownMenuItem(
                              value: 'pending',
                              child: Text('قيد الانتظار'),
                            ),
                            DropdownMenuItem(
                              value: 'approved',
                              child: Text('مقبول'),
                            ),
                            DropdownMenuItem(
                              value: 'rejected',
                              child: Text('مرفوض'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterStatus = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Deliveries List
            Expanded(
              child: BlocConsumer<DeliveryCubit, DeliveryState>(
                listener: (context, state) {
                  if (state is DeliveryApproved) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.green,
                      ),
                    );
                    context.read<DeliveryCubit>().getAllDeliveries();
                  } else if (state is DeliveryRejected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    context.read<DeliveryCubit>().getAllDeliveries();
                  } else if (state is DeliveryError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is DeliveryLoading) {
                    return const Center(child: AppLoadingIndicator());
                  }

                  if (state is DeliveryLoaded) {
                    final filteredDeliveries = _filterDeliveries(
                      state.deliveries,
                    );

                    if (filteredDeliveries.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 100,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'لا توجد طلبات معلقة',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredDeliveries.length,
                      itemBuilder: (context, index) {
                        final delivery = filteredDeliveries[index];
                        return _buildDeliveryCard(delivery);
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(DeliveryModel delivery) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.two_wheeler_rounded,
                    size: 35,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery.deliveryName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${delivery.city} - ${delivery.governorate}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(delivery.status),
              ],
            ),
            const Divider(height: 24),
            if (delivery.deliveryPhones.isNotEmpty) ...[
              ...delivery.deliveryPhones.asMap().entries.map((entry) {
                final index = entry.key;
                final phone = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildInfoRow(
                    Icons.phone,
                    delivery.deliveryPhones.length > 1
                        ? 'هاتف ${index + 1}'
                        : 'هاتف',
                    phone,
                  ),
                );
              }),
            ],
            _buildInfoRow(
              FontAwesomeIcons.whatsapp,
              'واتساب',
              delivery.deliveryWhatsApp,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.location_city,
              'المحافظة',
              delivery.governorate,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'المدينة', delivery.city),
            if (delivery.notes != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        delivery.notes!,
                        style: TextStyle(color: Colors.orange[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (delivery.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<DeliveryCubit>().approveDelivery(
                          delivery.id,
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('موافقة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRejectDialog(delivery.id),
                      icon: const Icon(Icons.close),
                      label: const Text('رفض'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (delivery.status == 'approved') ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<DeliveryCubit>().returnToPending(delivery.id);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('إرجاع لقيد الانتظار'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 0),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(color: Colors.grey[600])),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String statusText;
    IconData icon;

    switch (status) {
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        statusText = 'قيد الانتظار';
        icon = Icons.hourglass_empty;
        break;
      case 'approved':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        statusText = 'مقبول';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        statusText = 'مرفوض';
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade900;
        statusText = 'غير محدد';
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
