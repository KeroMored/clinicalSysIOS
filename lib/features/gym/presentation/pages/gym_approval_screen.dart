import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../../data/models/gym_model.dart';
import 'gym_details_screen.dart';

enum GymApprovalStatus {
  all,
  pending,
  approved,
}

class GymApprovalScreen extends StatefulWidget {
  const GymApprovalScreen({super.key});

  @override
  State<GymApprovalScreen> createState() => _GymApprovalScreenState();
}

class _GymApprovalScreenState extends State<GymApprovalScreen> {
  GymApprovalStatus _selectedStatus = GymApprovalStatus.pending;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'الموافقة على الجيمات',
        gradient: AppTheme.gymGradient,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterChip(
                    label: 'الكل',
                    status: GymApprovalStatus.all,
                    icon: Icons.list,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip(
                    label: 'قيد الانتظار',
                    status: GymApprovalStatus.pending,
                    icon: Icons.pending_actions,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip(
                    label: 'موافق عليها',
                    status: GymApprovalStatus.approved,
                    icon: Icons.check_circle,
                  ),
                ),
              ],
            ),
          ),

          // Gyms List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getGymsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('حدث خطأ: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد جيمات ${_getStatusText()}',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final gyms = snapshot.data!.docs
                    .map((doc) => GymModel.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: gyms.length,
                  itemBuilder: (context, index) {
                    return _buildGymCard(gyms[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required GymApprovalStatus status,
    required IconData icon,
  }) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : AppTheme.gymGradient.colors[0],
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        if (selected && mounted) {
          setState(() {
            _selectedStatus = status;
          });
        }
      },
      selectedColor: AppTheme.gymGradient.colors[0],
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.gymGradient.colors[0],
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(color: AppTheme.gymGradient.colors[0]),
    );
  }

  Stream<QuerySnapshot> _getGymsStream() {
    Query query = FirebaseFirestore.instance.collection('gyms');

    switch (_selectedStatus) {
      case GymApprovalStatus.pending:
        query = query.where('isApproved', isEqualTo: false);
        break;
      case GymApprovalStatus.approved:
        query = query.where('isApproved', isEqualTo: true);
        break;
      case GymApprovalStatus.all:
        // No filter, get all gyms
        break;
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  String _getStatusText() {
    switch (_selectedStatus) {
      case GymApprovalStatus.pending:
        return 'قيد الانتظار';
      case GymApprovalStatus.approved:
        return 'موافق عليها';
      case GymApprovalStatus.all:
        return '';
    }
  }

  Widget _buildGymCard(GymModel gym) {
    final dateFormat = DateFormat('dd/MM/yyyy - hh:mm a', 'ar');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GymDetailsScreen(gym: gym),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status badge
              Row(
                children: [
                  // Gym Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: gym.images.isNotEmpty
                        ? Image.network(
                            gym.images.first,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.fitness_center),
                              );
                            },
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.fitness_center),
                          ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Gym Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gym.name,
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
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                gym.address,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: gym.isApproved
                          ? Colors.green[100]
                          : Colors.orange[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: gym.isApproved
                            ? Colors.green[300]!
                            : Colors.orange[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          gym.isApproved ? Icons.check_circle : Icons.pending,
                          size: 16,
                          color: gym.isApproved
                              ? Colors.green[900]
                              : Colors.orange[900],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          gym.isApproved ? 'موافق' : 'انتظار',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: gym.isApproved
                                ? Colors.green[900]
                                : Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Owner Info
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'المالك: ${gym.ownerName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Sections
              Row(
                children: [
                  if (gym.hasMaleSection)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.male,
                            size: 14,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'رجالي',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (gym.hasMaleSection && gym.hasFemaleSection)
                    const SizedBox(width: 8),
                  if (gym.hasFemaleSection)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pink[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.pink[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.female,
                            size: 14,
                            color: Colors.pink[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'نسائي',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.pink[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Date Info
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'تاريخ الإضافة: ${dateFormat.format(gym.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              if (gym.isApproved && gym.approvedAt != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'تاريخ الموافقة: ${dateFormat.format(gym.approvedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GymDetailsScreen(gym: gym),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('عرض التفاصيل'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.gymGradient.colors[0],
                        side: BorderSide(
                          color: AppTheme.gymGradient.colors[0],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: gym.isApproved
                        ? ElevatedButton.icon(
                            onPressed: () => _changeStatus(gym, false),
                            icon: const Icon(Icons.undo),
                            label: const Text('إرجاع للانتظار'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () => _approveGym(gym),
                            icon: const Icon(Icons.check),
                            label: const Text('موافقة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                  ),
                  if (!gym.isApproved) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _rejectGym(gym),
                      icon: const Icon(Icons.close),
                      color: Colors.red,
                      tooltip: 'رفض',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approveGym(GymModel gym) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الموافقة'),
        content: Text('هل أنت متأكد من الموافقة على جيم "${gym.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('موافقة'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('gyms').doc(gym.id).update({
          'isApproved': true,
          'approvedAt': Timestamp.now(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تمت الموافقة على جيم "${gym.name}"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _changeStatus(GymModel gym, bool isApproved) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApproved ? 'تأكيد الموافقة' : 'إرجاع للانتظار'),
        content: Text(
          isApproved
              ? 'هل أنت متأكد من الموافقة على جيم "${gym.name}"؟'
              : 'هل أنت متأكد من إرجاع جيم "${gym.name}" لقائمة الانتظار؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproved ? Colors.green : Colors.orange,
            ),
            child: Text(isApproved ? 'موافقة' : 'إرجاع'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('gyms').doc(gym.id).update({
          'isApproved': isApproved,
          'approvedAt': isApproved ? Timestamp.now() : null,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isApproved
                    ? 'تمت الموافقة على جيم "${gym.name}"'
                    : 'تم إرجاع جيم "${gym.name}" لقائمة الانتظار',
              ),
              backgroundColor: isApproved ? Colors.green : Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rejectGym(GymModel gym) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الرفض'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من رفض جيم "${gym.name}"؟'),
            const SizedBox(height: 8),
            const Text(
              'سيتم حذف الجيم نهائياً من النظام.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('رفض وحذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('gyms').doc(gym.id).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم رفض وحذف جيم "${gym.name}"'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
