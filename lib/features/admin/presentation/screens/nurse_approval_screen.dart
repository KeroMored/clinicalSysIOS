import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';
import 'package:mallawycare/core/widgets/app_loading_indicator.dart';

class NurseApprovalScreen extends StatefulWidget {
  const NurseApprovalScreen({super.key});

  @override
  State<NurseApprovalScreen> createState() => _NurseApprovalScreenState();
}

class _NurseApprovalScreenState extends State<NurseApprovalScreen> {
  String _selectedFilter = 'pending';

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    if (_selectedFilter == 'pending') {
      context.read<AdminCubit>().loadPendingNurseRequests();
    } else {
      context.read<AdminCubit>().loadNurseRequestsByStatus(_selectedFilter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'الموافقة على الممرضين',
        gradient: AppTheme.nursingGradient,
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
            _buildFilterTabs(),
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

                  if (state is NurseRequestsLoaded) {
                    if (state.requests.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.medical_services_outlined,
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
                      onRefresh: () async => _loadRequests(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.requests.length,
                        itemBuilder: (context, index) {
                          return _buildNurseCard(state.requests[index]);
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

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.grey[200],
      child: Row(
        children: [
          _buildFilterTab('الكل', 'all'),
          _buildFilterTab('قيد الانتظار', 'pending'),
          _buildFilterTab('مقبولة', 'approved'),
          _buildFilterTab('مرفوضة', 'rejected'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedFilter = value);
          _loadRequests();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.teal : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.teal : Colors.transparent,
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
        return 'لا توجد طلبات قيد الانتظار';
      case 'approved':
        return 'لا توجد طلبات مقبولة';
      case 'rejected':
        return 'لا توجد طلبات مرفوضة';
      default:
        return 'لا توجد طلبات';
    }
  }

  Widget _buildNurseCard(Map<String, dynamic> nurseData) {
    final status = nurseData['status'] ?? 'pending';
    final createdAt =
        (nurseData['createdAt'] as dynamic)?.toDate() ?? DateTime.now();
    final gender = nurseData['gender'] ?? 'male';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.teal.shade50,
                  backgroundImage: nurseData['profileImageUrl'] != null
                      ? NetworkImage(nurseData['profileImageUrl'])
                      : null,
                  child: nurseData['profileImageUrl'] == null
                      ? Icon(
                          gender == 'male'
                              ? Icons.person
                              : Icons.person_outline,
                          size: 30,
                          color: Colors.teal,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nurseData['nurseName'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nurseData['specialization'] ?? '',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.person, gender == 'male' ? 'ممرض' : 'ممرضة'),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.work_history,
              '${nurseData['yearsOfExperience'] ?? 0} سنوات خبرة',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.location_on,
              '${nurseData['city']}, ${nurseData['governorate']}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, nurseData['nursePhone'] ?? ''),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.payments,
              'السعر: ${nurseData['hourlyRate']?.toInt() ?? 0} جنيه/ساعة',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today,
              'تاريخ الطلب: ${DateFormat('yyyy-MM-dd').format(createdAt)}',
            ),
            if (nurseData['services'] != null &&
                (nurseData['services'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'الخدمات:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (nurseData['services'] as List).take(3).map((
                  service,
                ) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      service.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveNurse(nurseData['id']),
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
                      onPressed: () => _rejectNurse(nurseData['id']),
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
                  onPressed: () => _deleteNurse(nurseData['id']),
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
        label = 'مقبول';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        label = 'مرفوض';
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
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }

  void _approveNurse(String nurseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الموافقة'),
        content: const Text('هل أنت متأكد من الموافقة على هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminCubit>().approveNurseRequest(nurseId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('موافقة'),
          ),
        ],
      ),
    );
  }

  void _rejectNurse(String nurseId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض الطلب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('يرجى إدخال سبب الرفض:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'سبب الرفض',
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
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                context.read<AdminCubit>().rejectNurseRequest(
                  nurseId,
                  reasonController.text.trim(),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }

  void _deleteNurse(String nurseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminCubit>().deleteNurseRequest(nurseId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
