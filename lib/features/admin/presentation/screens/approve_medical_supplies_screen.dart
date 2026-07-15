import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';
import '../widgets/medical_supply_request_card.dart';
import 'medical_supply_request_details_screen.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class ApproveMedicalSuppliesScreen extends StatefulWidget {
  const ApproveMedicalSuppliesScreen({super.key});

  @override
  State<ApproveMedicalSuppliesScreen> createState() =>
      _ApproveMedicalSuppliesScreenState();
}

class _ApproveMedicalSuppliesScreenState extends State<ApproveMedicalSuppliesScreen> {
  String _selectedFilter = 'pending'; // pending, rejected, all

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadMedicalSupplyRequestsByStatus(_selectedFilter);
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    context.read<AdminCubit>().loadMedicalSupplyRequestsByStatus(filter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'الموافقة على المستلزمات الطبية',
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AdminCubit>().loadMedicalSupplyRequestsByStatus(
                _selectedFilter,
              );
            },
          ),
        ],
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
            // Filter Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  const Text(
                    'التصفية: ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('الكل'),
                          selected: _selectedFilter == 'all',
                          onSelected: (selected) {
                            if (selected) _onFilterChanged('all');
                          },
                          selectedColor: Colors.green.shade200,
                          checkmarkColor: Colors.green.shade800,
                        ),
                        FilterChip(
                          label: const Text('في الانتظار'),
                          selected: _selectedFilter == 'pending',
                          onSelected: (selected) {
                            if (selected) _onFilterChanged('pending');
                          },
                          selectedColor: Colors.orange.shade200,
                          checkmarkColor: Colors.orange.shade800,
                        ),
                        FilterChip(
                          label: const Text('مرفوض'),
                          selected: _selectedFilter == 'rejected',
                          onSelected: (selected) {
                            if (selected) _onFilterChanged('rejected');
                          },
                          selectedColor: Colors.red.shade200,
                          checkmarkColor: Colors.red.shade800,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: BlocConsumer<AdminCubit, AdminState>(
                listener: (context, state) {
                  if (state is MedicalSupplyRequestApproved) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (state is MedicalSupplyRequestRejected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.orange,
                      ),
                    );
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

                  if (state is AdminError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'حدث خطأ: ${state.message}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context
                                  .read<AdminCubit>()
                                  .loadMedicalSupplyRequestsByStatus(
                                    _selectedFilter,
                                  );
                            },
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is MedicalSupplyRequestsLoaded) {
                    if (state.requests.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد طلبات في الانتظار',
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
                      onRefresh: () => context
                          .read<AdminCubit>()
                          .loadMedicalSupplyRequestsByStatus(_selectedFilter),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.requests.length,
                        itemBuilder: (context, index) {
                          final request = state.requests[index];
                          return MedicalSupplyRequestCard(
                            request: request,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BlocProvider.value(
                                    value: context.read<AdminCubit>(),
                                    child: MedicalSupplyRequestDetailsScreen(
                                      request: request,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  }

                  return const Center(child: Text('لا توجد بيانات'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
