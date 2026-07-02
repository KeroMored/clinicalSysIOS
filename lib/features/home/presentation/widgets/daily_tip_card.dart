import 'package:flutter/material.dart';

import '../../data/daily_health_tips.dart';

class DailyInfoCard extends StatelessWidget {
  const DailyInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final info = DailyHealthInfo.getInfoForDate(now);
    const accentColor = Color(0xFF0B8293);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.merge(
          Border(
            right: BorderSide(
              color: accentColor.withValues(alpha: 0.48),
              width: 1.5,
            ),
          ),
          Border(
            bottom: BorderSide(
              color: accentColor.withValues(alpha: 0.48),
              width: 0.000005,
            ),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF8FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD8ECF2)),
                ),
                child: const Icon(
                  Icons.info_rounded,
                  color: Color(0xFF0B8293),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'معلومة اليوم',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF8FA),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Text(
                            'مهمة',
                            style: TextStyle(
                              color: Color(0xFF0B8293),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'معلومة طبية مختصرة وموثوقة',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    //const SizedBox(height: 6),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FCFE),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFFE5EEF3)),
            ),
            child: Text(
              info,
              maxLines: 9,
              overflow: TextOverflow.fade,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 12.5,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class DailyTipCard extends DailyInfoCard {
  const DailyTipCard({super.key});
}
