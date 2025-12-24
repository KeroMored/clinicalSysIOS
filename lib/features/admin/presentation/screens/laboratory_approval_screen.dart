import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';
import '../../../laboratory/data/models/laboratory_model.dart';
import 'laboratory_detail_approval_screen.dart';

class LaboratoryApprovalScreen extends StatefulWidget {
  const LaboratoryApprovalScreen({super.key});

  @override
  State<LaboratoryApprovalScreen> createState() => _LaboratoryApprovalScreenState();
}

class _LaboratoryApprovalScreenState extends State<LaboratoryApprovalScreen> {
  String _selectedFilter = 'pending'; // all, pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    if (_selectedFilter == 'all') {
      context.read<AdminCubit>().loadAllLaboratoryRequests();
    } else if (_selectedFilter == 'pending') {
      context.read<AdminCubit>().loadPendingLaboratoryRequests();
    } else {
      context.read<AdminCubit>().loadLaboratoryRequestsByStatus(_selectedFilter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الموافقة على المعامل'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.green[50],
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterTab('الكل', 'all'),
                ),
                Expanded(
                  child: _buildFilterTab('قيد الانتظار', 'pending'),
                ),
                Expanded(
                  child: _buildFilterTab('مقبولة', 'approved'),
                ),
                Expanded(
                  child: _buildFilterTab('مرفوضة', 'rejected'),
                ),
              ],
            ),
          ),
          
          // Laboratory List
          Expanded(
            child: BlocBuilder<AdminCubit, AdminState>(
              builder: (context, state) {
                if (state is AdminLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (state is LaboratoryRequestsLoaded) {
                  if (state.laboratories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.science_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد طلبات',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
      
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.laboratories.length,
                    itemBuilder: (context, index) {
                      final lab = state.laboratories[index];
                      return _buildLaboratoryCard(lab);
                    },
                  );
                }
      
                return const Center(child: Text('حدث خطأ'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String filter) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = filter);
        _loadRequests();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.green : Colors.transparent,
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
            color: isSelected ? Colors.green : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildLaboratoryCard(LaboratoryModel lab) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (lab.status) {
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LaboratoryDetailApprovalScreen(
                laboratory: lab,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with logo and status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: lab.logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              lab.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.science,
                                color: Colors.green,
                                size: 30,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.science,
                            color: Colors.green,
                            size: 30,
                          ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Lab name and date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lab.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'تاريخ الطلب: ${DateFormat('yyyy/MM/dd').format(lab.createdAt)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Laboratory Summary
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(Icons.person, 'المالك', lab.ownerName),
                  _buildDetailRow(Icons.phone, 'هاتف المالك', lab.ownerPhone),
                  _buildDetailRow(Icons.location_on, 'العنوان', lab.address),
                  
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.science, size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${lab.availableTests.length} تحليل متاح',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (lab.hasHomeService)
                        const Icon(Icons.home, size: 18, color: Colors.blue),
                    ],
                  ),
                  
                  if (lab.status == 'rejected' && lab.rejectionReason != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'سبب الرفض: ${lab.rejectionReason}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app, size: 16, color: Colors.grey),
                      SizedBox(width: 6),
                      Text(
                        'اضغط لعرض التفاصيل',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
