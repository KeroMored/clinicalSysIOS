import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';
import '../../../clinic/data/models/clinic_department.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class ClinicApprovalScreen extends StatefulWidget {
  const ClinicApprovalScreen({super.key});

  @override
  State<ClinicApprovalScreen> createState() => _ClinicApprovalScreenState();
}

class _ClinicApprovalScreenState extends State<ClinicApprovalScreen> {
  String _selectedFilter = 'pending'; // all, pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    if (_selectedFilter == 'pending') {
      context.read<AdminCubit>().loadPendingClinicRequests();
    } else {
      context.read<AdminCubit>().loadClinicRequestsByStatus(_selectedFilter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'الموافقة على العيادات',
        gradient: AppTheme.clinicGradient,
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
            // Filter Tabs
            Container(
              color: Colors.grey[200],
              child: Row(
                children: [
                  _buildFilterTab('الكل', 'all'),
                  _buildFilterTab('قيد الانتظار', 'pending'),
                  _buildFilterTab('مقبولة', 'approved'),
                  _buildFilterTab('مرفوضة', 'rejected'),
                ],
              ),
            ),
            // Requests List
            Expanded(
              child: BlocConsumer<AdminCubit, AdminState>(
                listener: (context, state) {
                  if (state is RequestApproved) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadRequests();
                  } else if (state is RequestRejected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    _loadRequests();
                  } else if (state is AdminError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is AdminLoading) {
                    return const Center(child: AppLoadingIndicator());
                  }

                  if (state is ClinicRequestsLoaded) {
                    if (state.requests.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_hospital_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _getEmptyMessage(),
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        _loadRequests();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.requests.length,
                        itemBuilder: (context, index) {
                          final clinicData = state.requests[index];
                          return _buildClinicCard(clinicData);
                        },
                      ),
                    );
                  }

                  return const Center(child: Text('حدث خطأ ما'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
          _loadRequests();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.purple : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.purple : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  String _getEmptyMessage() {
    switch (_selectedFilter) {
      case 'pending':
        return 'لا توجد عيادات قيد الانتظار';
      case 'approved':
        return 'لا توجد عيادات مقبولة';
      case 'rejected':
        return 'لا توجد عيادات مرفوضة';
      default:
        return 'لا توجد عيادات';
    }
  }

  Widget _buildClinicCard(Map<String, dynamic> clinicData) {
    final status = clinicData['status'] ?? 'pending';
    final createdAt =
        (clinicData['createdAt'] as dynamic)?.toDate() ?? DateTime.now();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'د. ${clinicData['doctorName'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (clinicData['specialization'] is List)
                            ? (clinicData['specialization'] as List).join(' • ')
                            : (clinicData['specialization']?.toString() ?? ''),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const Divider(height: 24),

            // Clinic Info
            _buildInfoRow(
              Icons.category,
              ClinicDepartment.fromString(
                clinicData['department'] ?? 'other',
              ).arabicName,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, clinicData['address'] ?? ''),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, clinicData['phone'] ?? ''),
            if (clinicData['whatsapp'] != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(FontAwesomeIcons.whatsapp, clinicData['whatsapp']),
            ],
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.attach_money,
              'سعر الكشف: ${clinicData['consultationFee']?.toInt() ?? 0} جنيه',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.email,
              (clinicData['doctorEmails'] as List<dynamic>?)?.isNotEmpty == true
                  ? (clinicData['doctorEmails'] as List<dynamic>).first
                        .toString()
                  : clinicData['doctorEmail'] ?? 'لا يوجد',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today,
              'تاريخ الطلب: ${DateFormat('yyyy-MM-dd').format(createdAt)}',
            ),

            // Action Buttons
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveClinic(clinicData['id']),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('قبول'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectClinic(clinicData['id']),
                      icon: const Icon(Icons.cancel),
                      label: const Text('رفض'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (status == 'rejected' || status == 'approved') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _deleteClinic(clinicData['id']),
                  icon: const Icon(Icons.delete),
                  label: const Text('حذف'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'approved':
        color = Colors.green;
        label = 'مقبولة';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        label = 'مرفوضة';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange;
        label = 'قيد الانتظار';
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  void _approveClinic(String clinicId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد القبول'),
        content: const Text('هل أنت متأكد من قبول هذه العيادة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminCubit>().approveClinicRequest(clinicId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('قبول'),
          ),
        ],
      ),
    );
  }

  void _rejectClinic(String clinicId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض العيادة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('هل أنت متأكد من رفض هذه العيادة؟'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الرفض (اختياري)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              Navigator.pop(context);
              context.read<AdminCubit>().rejectClinicRequest(
                clinicId,
                reasonController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }

  void _deleteClinic(String clinicId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
          'هل أنت متأكد من حذف هذه العيادة نهائياً؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminCubit>().deleteClinic(clinicId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
