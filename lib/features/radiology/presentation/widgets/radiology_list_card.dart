import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/radiology_model.dart';
import '../cubit/radiology_cubit.dart';
import '../screens/radiology_detail_approval_screen.dart';
import 'radiology_status_badge.dart';

class RadiologyListCard extends StatelessWidget {
  final RadiologyModel radiology;

  const RadiologyListCard({super.key, required this.radiology});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade200, width: 2),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RadiologyDetailApprovalScreen(radiology: radiology),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildLocationAndDate(),
              const SizedBox(height: 12),
              _buildFeatures(),
              const SizedBox(height: 12),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.local_hospital,
            color: Colors.deepPurple,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                radiology.centerName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      radiology.ownerName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        RadiologyStatusBadge(isApproved: radiology.isApproved),
      ],
    );
  }

  Widget _buildLocationAndDate() {
    return Row(
      children: [
        const Icon(Icons.location_on, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${radiology.city}, ${radiology.governorate}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          DateFormat('yyyy-MM-dd').format(radiology.createdAt),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildFeatures() {
    return Row(
      children: [
        if (radiology.homeVisit)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.home, size: 12, color: Colors.blue.shade700),
                const SizedBox(width: 4),
                Text(
                  'زيارة منزلية',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                Icons.medical_services,
                size: 12,
                color: Colors.deepPurple.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                '${radiology.services.length} خدمة',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.deepPurple.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (radiology.isApproved)
          TextButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('إرجاع لقيد الانتظار'),
                  content: Text(
                    'هل تريد إرجاع "${radiology.centerName}" لقيد الانتظار؟',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('إرجاع'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await context.read<RadiologyCubit>().returnToPending(
                  radiology.id,
                );
              }
            },
            icon: const Icon(Icons.undo, size: 18),
            label: const Text('إرجاع'),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
          ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    RadiologyDetailApprovalScreen(radiology: radiology),
              ),
            );
          },
          icon: const Icon(Icons.visibility, size: 18),
          label: const Text('عرض التفاصيل'),
          style: TextButton.styleFrom(foregroundColor: Colors.teal),
        ),
      ],
    );
  }
}
