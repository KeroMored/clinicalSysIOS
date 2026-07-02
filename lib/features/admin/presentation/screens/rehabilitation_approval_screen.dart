import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../../rehabilitation/data/models/rehabilitation_center_model.dart';
import '../../../rehabilitation/presentation/cubit/rehabilitation_cubit.dart';
import '../../../rehabilitation/presentation/cubit/rehabilitation_state.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class RehabilitationApprovalScreen extends StatefulWidget {
  const RehabilitationApprovalScreen({super.key});

  @override
  State<RehabilitationApprovalScreen> createState() =>
      _RehabilitationApprovalScreenState();
}

class _RehabilitationApprovalScreenState
    extends State<RehabilitationApprovalScreen> {
  String _filterServiceType = 'all';
  String _filterStatus = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<RehabilitationCubit>().getAllCenters();
  }

  List<RehabilitationCenterModel> _filterCenters(
    List<RehabilitationCenterModel> centers,
  ) {
    return centers.where((center) {
      final matchesSearch =
          center.centerName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          center.directorName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          center.phone.contains(_searchQuery) ||
          center.address.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesService =
          _filterServiceType == 'all' ||
          center.serviceTypes.contains(_filterServiceType);

      final matchesStatus =
          _filterStatus == 'all' ||
          (_filterStatus == 'pending' && center.status == 'pending') ||
          (_filterStatus == 'approved' && center.status == 'approved') ||
          (_filterStatus == 'rejected' && center.status == 'rejected');

      return matchesSearch && matchesService && matchesStatus;
    }).toList();
  }

  Future<void> _showRejectDialog(String centerId) async {
    final TextEditingController reasonController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سبب الرفض'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'أدخل سبب رفض المركز',
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
                context.read<RehabilitationCubit>().rejectCenter(
                  centerId,
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
        title: 'الموافقة على مراكز التأهيل',
        gradient: AppTheme.rehabilitationGradient,
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
                  const SizedBox(height: 12),
                  // Service Type Filter
                  Row(
                    children: [
                      const Text(
                        'الخدمة:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filterServiceType,
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
                          items: [
                            const DropdownMenuItem(
                              value: 'all',
                              child: Text('الكل'),
                            ),
                            ...RehabilitationTypes.allTypes.map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterServiceType = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Centers List
            Expanded(
              child: BlocConsumer<RehabilitationCubit, RehabilitationState>(
                listener: (context, state) {
                  if (state is RehabilitationApproved) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.green,
                      ),
                    );
                    context.read<RehabilitationCubit>().getAllCenters();
                  } else if (state is RehabilitationRejected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    context.read<RehabilitationCubit>().getAllCenters();
                  } else if (state is RehabilitationError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is RehabilitationLoading) {
                    return const Center(child: AppLoadingIndicator());
                  }

                  if (state is RehabilitationLoaded) {
                    final filteredCenters = _filterCenters(state.centers);

                    if (filteredCenters.isEmpty) {
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
                              'لا توجد مراكز',
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
                      itemCount: filteredCenters.length,
                      itemBuilder: (context, index) {
                        final center = filteredCenters[index];
                        return _buildCenterCard(center);
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

  Widget _buildCenterCard(RehabilitationCenterModel center) {
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
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.purple[100],
                  backgroundImage: center.profileImageUrl != null
                      ? NetworkImage(center.profileImageUrl!)
                      : null,
                  child: center.profileImageUrl == null
                      ? const Icon(
                          Icons.business,
                          size: 35,
                          color: Colors.purple,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        center.centerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'المدير: ${center.directorName}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(center.status),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: center.serviceTypes
                  .map(
                    (type) => Chip(
                      label: Text(type, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.purple[50],
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, 'هاتف', center.phone),
            if (center.whatsapp != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(FontAwesomeIcons.whatsapp, 'واتساب', center.whatsapp!),
            ],
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'العنوان', center.address),
            if (center.hasHomeService) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.home, size: 20, color: Colors.purple),
                  const SizedBox(width: 8),
                  const Text(
                    'يوجد خدمة منزلية',
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'الوصف:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              center.description,
              style: TextStyle(color: Colors.grey[600]),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (center.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سبب الرفض: ${center.rejectionReason}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (center.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<RehabilitationCubit>().approveCenter(
                          center.id,
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
                      onPressed: () => _showRejectDialog(center.id),
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
