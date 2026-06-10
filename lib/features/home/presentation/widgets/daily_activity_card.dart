import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/daily_activity_model.dart';
import '../../services/daily_step_tracking_service.dart';
import 'package:mallawycare/core/widgets/app_loading_indicator.dart';

class DailyActivityCard extends StatefulWidget {
  final VoidCallback? onGuestTap;

  const DailyActivityCard({super.key, this.onGuestTap});

  @override
  State<DailyActivityCard> createState() => _DailyActivityCardState();
}

class _DailyActivityCardState extends State<DailyActivityCard> {
  static const Color _accentColor = Color(0xFF0B8293);
  final DailyStepTrackingService _trackingService = DailyStepTrackingService();
  bool _isRefreshing = false;

  Future<void> _refreshNow(String userId) async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      final granted =
          _trackingService.permissionGrantedNotifier.value ||
          await _trackingService.requestActivityPermissionFromCard();

      if (granted) {
        await _trackingService.start(userId, requestPermissionIfDenied: false);
        await _trackingService.refreshFromSensorOnceForceTouch();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فعّل إذن النشاط البدني أولاً.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    if (authState is! Authenticated) {
      return _buildGuestCard();
    }

    return ValueListenableBuilder<DailyActivityModel?>(
      valueListenable: _trackingService.todayNotifier,
      builder: (context, model, _) {
        final today =
            model ??
            DailyActivityModel(
              dateKey: DailyActivityModel.buildDateKey(DateTime.now()),
              steps: 0,
              meters: 0,
              updatedAt: DateTime.now(),
            );

        final progress = today.progressToNextLevel;
        // final progressPercent = (progress * 100).round();
        final distanceInKm = today.meters / 1000;
        final burnedCalories = (today.steps * 0.04).round();
        final remainingMeters = (today.remainingStepsToNextLevel * 0.75)
            .round();
        final nextLevelMessage = today.isTopPerformanceLevel
            ? 'وصلت لأعلى مستوى اليوم، كمل يا بطل'
            : 'باقي $remainingMeters متر لتخطي المستوى';

        final updated = today.updatedAt;
        final updatedAtLabel =
            '${updated.hour.toString().padLeft(2, '0')}:${updated.minute.toString().padLeft(2, '0')}';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _refreshNow(authState.user.uid),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.merge(
                  Border(
                    right: BorderSide(
                      color: _accentColor.withValues(alpha: 0.48),
                      width: 2,
                    ),
                  ),
                  Border(
                    bottom: BorderSide(
                      color: _accentColor.withValues(alpha: 0.48),
                      width: 0.000005,
                    ),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Container(
                      //   width: 32,
                      //   height: 32,
                      //   decoration: BoxDecoration(
                      //     color: const Color(0xFFEAF7FA),
                      //     borderRadius: BorderRadius.circular(10),
                      //   ),
                      //   child: const Icon(
                      //     Icons.directions_walk_rounded,
                      //     size: 18,
                      //     color: _accentColor,
                      //   ),
                      // ),
                      // const SizedBox(width: 8),
                      // const Expanded(
                      //   child: Text(
                      //     'المشي اليومي',
                      //     style: TextStyle(
                      //       color: Color(0xFF0F172A),
                      //       fontSize: 13,
                      //       fontWeight: FontWeight.w800,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  //   const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildProgressRing(progress),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${today.steps} خطوة',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            // const SizedBox(height: 2),
                            // const Text(
                            //   'إجمالي الخطوات اليوم',
                            //   style: TextStyle(
                            //     color: Color(0xFF64748B),
                            //     fontSize: 10,
                            //     fontWeight: FontWeight.w700,
                            //  ),
                            // ),
                            const SizedBox(height: 3),
                            Text(
                              '${today.meters.toStringAsFixed(0)} متر',
                              style: const TextStyle(
                                color: Color(0xFF3B556E),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            // const SizedBox(height: 4),
                            // Text(
                            //   '$progressPercent% من المستوى الحالي',
                            //   style: const TextStyle(
                            //     color: _accentColor,
                            //     fontSize: 10,
                            //     fontWeight: FontWeight.w700,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            updatedAtLabel,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            onPressed: _isRefreshing
                                ? null
                                : () => _refreshNow(authState.user.uid),
                            tooltip: _isRefreshing
                                ? 'جاري تحديث المسافة...'
                                : 'تحديث المسافة',
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                              child: _isRefreshing
                                  ? const SizedBox(
                                      key: ValueKey('distance_loading'),
                                      width: 18,
                                      height: 18,
                                      child: AppLoadingIndicator(
                                        strokeWidth: 2,
                                        color: _accentColor,
                                      ),
                                    )
                                  : Container(
                                      key: const ValueKey('distance_refresh'),
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF2F8FA),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.refresh_rounded,
                                        color: _accentColor,
                                        size: 18,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  //    const SizedBox(height: 8),
                  // AppLoadingIndicator(
                  //   value: progress,
                  //   minHeight: 6,
                  //   borderRadius: BorderRadius.circular(99),
                  //   backgroundColor: const Color(0xFFE8F2F6),
                  //   valueColor: const AlwaysStoppedAnimation(_accentColor),
                  // ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FCFE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE4EDF2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.route_rounded,
                                size: 14,
                                color: _accentColor,
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'المسافة',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${distanceInKm.toStringAsFixed(1)} كم',
                                style: const TextStyle(
                                  color: Color(0xFF334155),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFAF5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF2E6D6)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                size: 14,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'السعرات',
                                style: TextStyle(
                                  color: Color(0xFF9A6C2F),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$burnedCalories',
                                style: const TextStyle(
                                  color: Color(0xFF334155),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nextLevelMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressRing(double progress) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: AppLoadingIndicator(
              value: 1,
              strokeWidth: 5,
              color: Color(0xFFE2EEF2),
              backgroundColor: Color(0xFFE2EEF2),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return SizedBox(
                width: 56,
                height: 56,
                child: AppLoadingIndicator(
                  value: value,
                  strokeWidth: 5,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation(_accentColor),
                ),
              );
            },
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F8FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD7E6EB)),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.directions_run_rounded,
              color: _accentColor,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCard() {
    final guestAccentBorderColor = _accentColor.withValues(alpha: 0.48);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onGuestTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.merge(
              Border(
                right: BorderSide(color: guestAccentBorderColor, width: 0.45),
              ),
              Border(
                bottom: BorderSide(color: guestAccentBorderColor, width: 2),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 18, color: _accentColor),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'سجّل دخولك لبدء تتبع خطواتك اليومية',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
