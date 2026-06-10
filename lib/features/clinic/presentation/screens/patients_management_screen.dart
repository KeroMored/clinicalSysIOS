import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/patient_cubit.dart';
import '../cubit/patient_state.dart';
import '../widgets/patient_card.dart';
import 'add_patient_screen.dart';
import 'package:mallawycare/core/widgets/app_loading_indicator.dart';

class PatientsManagementScreen extends StatefulWidget {
  final String clinicId;

  const PatientsManagementScreen({super.key, required this.clinicId});

  @override
  State<PatientsManagementScreen> createState() =>
      _PatientsManagementScreenState();
}

class _PatientsManagementScreenState extends State<PatientsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  static const Color _primaryColor = Color(0xFF0B8293);
  static const Color _backgroundColor = Color(0xFFF3F8FB);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    context.read<PatientCubit>().loadClinicPatients(widget.clinicId);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.extentAfter < 240) {
      context.read<PatientCubit>().loadMoreClinicPatients();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: Container(
          color: _backgroundColor,
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildSearchBar(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: context.read<PatientCubit>(),
                  child: AddPatientScreen(clinicId: widget.clinicId),
                ),
              ),
            );
          },
          icon: const Icon(Icons.person_add),
          label: const Text('إضافة مريض'),
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE7EF)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _textPrimary,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'متابعة المرضى',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.people_rounded,
              color: _primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(color: _textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'ابحث عن مريض...',
          hintStyle: const TextStyle(color: _textSecondary, fontSize: 12),
          prefixIcon: const Icon(Icons.search, color: _primaryColor, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDE7EF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDE7EF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return BlocConsumer<PatientCubit, PatientState>(
      listener: (context, state) {
        if (state is PatientActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          context.read<PatientCubit>().loadClinicPatients(widget.clinicId);
        } else if (state is PatientError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is PatientLoading) {
          return const Center(child: AppLoadingIndicator(color: _primaryColor));
        }

        if (state is PatientsLoaded) {
          final filteredPatients = state.patients.where((patient) {
            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery.toLowerCase();
            return patient.name.toLowerCase().contains(query) ||
                patient.phoneNumber.contains(query);
          }).toList();

          if (filteredPatients.isEmpty && !state.isLoadingMore) {
            return _buildEmptyState();
          }

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFDDE7EF))),
            ),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  filteredPatients.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filteredPatients.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: AppLoadingIndicator(
                          strokeWidth: 2.5,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  );
                }

                return PatientCard(
                  patient: filteredPatients[index],
                  clinicId: widget.clinicId,
                );
              },
            ),
          );
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFDDE7EF))),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 72, color: Colors.grey[350]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'لا يوجد مرضى' : 'لم يتم العثور على نتائج',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'ابدأ بإضافة المرضى من الزر أدناه'
                  : 'حاول البحث باسم أو رقم آخر',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
