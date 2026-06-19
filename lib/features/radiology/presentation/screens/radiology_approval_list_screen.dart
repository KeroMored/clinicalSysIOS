import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/radiology_cubit.dart';
import '../cubit/radiology_state.dart';
import '../../data/models/radiology_model.dart';
import '../widgets/widgets.dart';
import 'package:mallawicure/core/widgets/app_loading_indicator.dart';

class RadiologyApprovalListScreen extends StatefulWidget {
  const RadiologyApprovalListScreen({super.key});

  @override
  State<RadiologyApprovalListScreen> createState() =>
      _RadiologyApprovalListScreenState();
}

class _RadiologyApprovalListScreenState
    extends State<RadiologyApprovalListScreen> {
  String _selectedFilter = 'all'; // all, pending, approved

  @override
  void initState() {
    super.initState();
    _loadCenters();
  }

  void _loadCenters() {
    if (_selectedFilter == 'pending') {
      context.read<RadiologyCubit>().loadPendingRadiologyCenters();
    } else if (_selectedFilter == 'approved') {
      context.read<RadiologyCubit>().loadApprovedRadiologyCentersForAdmin();
    } else {
      context.read<RadiologyCubit>().loadAllRadiologyCenters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة مراكز الأشعة'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCenters),
        ],
      ),
      body: Column(
        children: [
          RadiologyFilterChips(
            selectedFilter: _selectedFilter,
            onFilterChanged: (value) {
              setState(() {
                _selectedFilter = value;
              });
              _loadCenters();
            },
          ),
          Expanded(
            child: BlocBuilder<RadiologyCubit, RadiologyState>(
              builder: (context, state) {
                if (state is RadiologyLoading) {
                  return const Center(
                    child: AppLoadingIndicator(color: Colors.teal),
                  );
                }

                if (state is RadiologyError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadCenters,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                List<RadiologyModel> centers = [];
                if (state is RadiologyPendingLoaded) {
                  centers = state.pendingCenters;
                } else if (state is RadiologyLoaded) {
                  centers = state.radiologyCenters;
                }

                if (centers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: Colors.green.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد مراكز',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: centers.length,
                  itemBuilder: (context, index) {
                    final radiology = centers[index];
                    return RadiologyListCard(radiology: radiology);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
