import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/laboratory_model.dart';
import 'laboratory_control_page.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

/// إدارة مالك معمل التحاليل
/// يتم توجيه المالك إلى صفحة التحكم الخاصة بالمعمل
class LaboratoryOwnerDashboard extends StatefulWidget {
  const LaboratoryOwnerDashboard({Key? key}) : super(key: key);

  @override
  State<LaboratoryOwnerDashboard> createState() =>
      _LaboratoryOwnerDashboardState();
}

class _LaboratoryOwnerDashboardState extends State<LaboratoryOwnerDashboard> {
  static const Color _primaryColor = Color(0xFF0B8293);

  SliverAppBar _buildOwnerSliverAppBar(String title) {
    return SliverAppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      centerTitle: true,
      pinned: true,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B8293), Color(0xFF179AAC)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;

    if (authState is! Authenticated) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0.5,
          centerTitle: true,
          title: const Text(
            'لوحة التحكم',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          iconTheme: const IconThemeData(color: _primaryColor),
        ),
        body: const Center(child: Text('الرجاء تسجيل الدخول')),
      );
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('laboratories')
            .where('authEmails', arrayContains: authState.user.email)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CustomScrollView(
              slivers: [
                _buildOwnerSliverAppBar('إدارة المعامل'),
                const SliverFillRemaining(
                  child: Center(child: AppLoadingIndicator()),
                ),
              ],
            );
          }

          if (snapshot.hasError) {
            return CustomScrollView(
              slivers: [
                _buildOwnerSliverAppBar('إدارة المعامل'),
                SliverFillRemaining(
                  child: Center(child: Text('حدث خطأ: ${snapshot.error}')),
                ),
              ],
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return CustomScrollView(
              slivers: [
                _buildOwnerSliverAppBar('إدارة المعامل'),
                const SliverFillRemaining(
                  child: Center(child: Text('لا توجد معامل مسجلة باسمك')),
                ),
              ],
            );
          }

          // If only one laboratory, navigate directly to its control page
          if (snapshot.data!.docs.length == 1) {
            final laboratory = LaboratoryModel.fromFirestore(
              snapshot.data!.docs.first,
            );

            // Navigate to control page immediately
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      LaboratoryControlPage(laboratory: laboratory),
                ),
              );
            });

            return CustomScrollView(
              slivers: [
                _buildOwnerSliverAppBar('إدارة المعامل'),
                const SliverFillRemaining(
                  child: Center(child: AppLoadingIndicator()),
                ),
              ],
            );
          }

          // If multiple laboratories, show list
          final laboratories = snapshot.data!.docs
              .map((doc) => LaboratoryModel.fromFirestore(doc))
              .toList();

          return CustomScrollView(
            slivers: [
              _buildOwnerSliverAppBar('معاملك (${laboratories.length})'),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final laboratory = laboratories[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ModernCard(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundImage:
                                laboratory.logoUrl != null &&
                                    laboratory.logoUrl!.isNotEmpty
                                ? NetworkImage(laboratory.logoUrl!)
                                : null,
                            child:
                                laboratory.logoUrl == null ||
                                    laboratory.logoUrl!.isEmpty
                                ? const Icon(Icons.biotech, size: 30)
                                : null,
                          ),
                          title: Text(
                            laboratory.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      laboratory.address,
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    laboratory.ownerPhone.isNotEmpty
                                        ? laboratory.ownerPhone
                                        : 'لا يوجد',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppTheme.laboratoryGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'إدارة',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LaboratoryControlPage(
                                  laboratory: laboratory,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }, childCount: laboratories.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
