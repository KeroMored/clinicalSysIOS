import 'package:flutter/material.dart';
import '../../data/models/medicine_model.dart';

class MedicineCard extends StatelessWidget {
  final MedicineModel medicine;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const MedicineCard({
    super.key,
    required this.medicine,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  static const Color _primaryColor = Color(0xFF0B8293);
  static const Color _primaryDark = Color(0xFF0FA8BC);
  static const Color _titleColor = Color(0xFF1E3A5F);
  static const LinearGradient _cardAccentGradient = LinearGradient(
    colors: [_primaryColor, _primaryDark],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  @override
  Widget build(BuildContext context) {
    final hasImage =
        medicine.imageUrl != null && medicine.imageUrl!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatar(hasImage),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNames(),
                          const SizedBox(height: 6),
                          _buildStatusBadge(),
                          const SizedBox(height: 7),
                          Text(
                            _buildNextReminderText(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      children: [
                        Transform.scale(
                          scale: 0.82,
                          child: Switch(
                            value: medicine.isActive,
                            onChanged: (_) => onToggle(),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            activeColor: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            onPressed: onDelete,
                            tooltip: 'حذف',
                            icon: const Icon(Icons.delete_outline_rounded),
                            color: const Color(0xFFDC2626),
                            iconSize: 19,
                            constraints: const BoxConstraints(
                              minHeight: 34,
                              minWidth: 34,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F5),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: _primaryColor.withOpacity(0.18)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.repeat_rounded,
                        size: 15,
                        color: _primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _getRepeatTypeText(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Text(
                        'اضغط للتعديل',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (medicine.reminderTimes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: medicine.reminderTimes
                        .map((time) => _buildTimeChip(_formatTime(time)))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool hasImage) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: hasImage ? null : _cardAccentGradient,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: hasImage
            ? Image.network(
                medicine.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFEAF7F5),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: _primaryColor,
                    size: 24,
                  ),
                ),
              )
            : const Icon(
                Icons.medication_rounded,
                color: Colors.white,
                size: 28,
              ),
      ),
    );
  }

  Widget _buildNames() {
    if (medicine.medicineNames.isEmpty) {
      return const Text(
        'دواء بدون اسم',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
        ),
      );
    }

    if (medicine.medicineNames.length == 1) {
      return Text(
        medicine.medicineNames.first,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _titleColor,
        ),
      );
    }

    final visible = medicine.medicineNames.take(2).join(' + ');
    final remain = medicine.medicineNames.length - 2;

    return Text(
      remain > 0 ? '$visible +$remain' : visible,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _titleColor,
      ),
    );
  }

  Widget _buildStatusBadge() {
    final Color badgeColor = medicine.isActive
        ? const Color(0xFF10B981)
        : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            medicine.isActive
                ? Icons.notifications_active
                : Icons.notifications_off,
            size: 12,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            medicine.isActive ? 'منبه مفعل' : 'منبه متوقف',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(String timeLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primaryColor.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_rounded, size: 12, color: _primaryColor),
          const SizedBox(width: 4),
          Text(
            timeLabel,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _titleColor,
            ),
          ),
        ],
      ),
    );
  }

  String _buildNextReminderText() {
    final next = medicine.getNextReminderTime();
    if (next == null) {
      return 'لا يوجد موعد قادم';
    }

    final now = DateTime.now();
    final diff = next.difference(now);
    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes.clamp(1, 59);
      return 'الموعد القادم بعد $minutes دقيقة';
    }

    if (diff.inHours < 24) {
      return 'الموعد القادم بعد ${diff.inHours} ساعة';
    }

    return 'الموعد القادم خلال ${diff.inDays} يوم';
  }

  // Get repeat type text with day names for specificDays
  String _getRepeatTypeText() {
    if (medicine.repeatType == RepeatType.specificDays &&
        medicine.specificDays != null &&
        medicine.specificDays!.isNotEmpty) {
      final dayNames = medicine.specificDays!
          .map((day) => _getArabicDayName(day))
          .join(' و ');
      return 'أيام محددة ($dayNames)';
    }
    return medicine.repeatType.arabicName;
  }

  String _getArabicDayName(int weekday) {
    const days = {
      1: 'اثنين',
      2: 'ثلاثاء',
      3: 'أربعاء',
      4: 'خميس',
      5: 'جمعة',
      6: 'سبت',
      7: 'أحد',
    };
    return days[weekday] ?? '';
  }

  String _formatTime(String time24) {
    final parts = time24.split(':');
    int hour = int.parse(parts[0]);
    final minute = parts[1];

    String period = 'ص';
    if (hour >= 12) {
      period = 'م';
      if (hour > 12) hour -= 12;
    } else if (hour == 0) {
      hour = 12;
    }

    return '${hour.toString()}:$minute $period';
  }
}
