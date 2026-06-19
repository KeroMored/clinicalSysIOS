import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/emergency_repository.dart';
import '../../data/models/emergency_number_model.dart';
import '../cubit/emergency_cubit.dart';
import '../cubit/emergency_state.dart';
import '../widgets/emergency_card.dart';
import 'package:mallawicure/core/widgets/app_loading_indicator.dart';

class EmergencyNumbersScreen extends StatelessWidget {
  const EmergencyNumbersScreen({super.key});

  static const Color _primaryColor = Color(0xFF0B8293);
  static const Color _primaryDark = Color(0xFF0FA8BC);
  static const Color _titleColor = Color(0xFF1E3A5F);

  static const LinearGradient _screenHeaderGradient = LinearGradient(
    colors: [_primaryColor, _primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          EmergencyCubit(EmergencyRepository())..loadEmergencyNumbers(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          scrolledUnderElevation: 0,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'أرقام الطوارئ',
            style: TextStyle(
              color: _titleColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF5FAF9), Color(0xFFEDF4F3)],
            ),
          ),
          child: BlocConsumer<EmergencyCubit, EmergencyState>(
            listener: (context, state) {
              if (state is EmergencyError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: const Color(0xFFB91C1C),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is EmergencyLoading) {
                return const Center(
                  child: AppLoadingIndicator(color: _primaryColor),
                );
              }

              if (state is EmergencyLoaded) {
                return RefreshIndicator(
                  color: _primaryColor,
                  onRefresh: () async {
                    context.read<EmergencyCubit>().loadEmergencyNumbers();
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: _buildHeroCard(state.numbers),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: _buildQuickActions(context, state.numbers),
                        ),
                      ),
                      const SliverPadding(
                        padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            'اختر الخدمة المطلوبة',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _titleColor,
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList.separated(
                          itemBuilder: (context, index) => EmergencyCard(
                            emergencyNumber: state.numbers[index],
                          ),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemCount: state.numbers.length,
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        sliver: SliverToBoxAdapter(child: _buildBottomInfo()),
                      ),
                    ],
                  ),
                );
              }

              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.signal_wifi_off_rounded,
                      size: 38,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'تعذر تحميل أرقام الطوارئ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<EmergencyCubit>().loadEmergencyNumbers();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(List<EmergencyNumberModel> numbers) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: _screenHeaderGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.emergency_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اتصال سريع بالطوارئ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${numbers.length} جهات متاحة على مدار 24 ساعة',
                  style: const TextStyle(
                    color: Color(0xFFDCFCE7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    List<EmergencyNumberModel> numbers,
  ) {
    final quickNumbers = numbers.take(3).toList();
    if (quickNumbers.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = quickNumbers[index];
          return ActionChip(
            avatar: Icon(item.icon, size: 16, color: item.color),
            label: Text(
              '${item.title} - ${item.number}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _titleColor,
              ),
            ),
            side: BorderSide(color: item.color.withOpacity(0.35)),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onPressed: () {
              context.read<EmergencyCubit>().makeCall(item.number);
            },
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: quickNumbers.length,
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: _primaryColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'استخدم هذه الأرقام فقط في الحالات العاجلة. عند الاتصال، اذكر موقعك بوضوح لتسريع الاستجابة.',
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey[800],
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
