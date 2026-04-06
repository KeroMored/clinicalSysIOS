import 'package:flutter/material.dart';
import '../../data/models/medicine_model.dart';

class ScheduleSelector extends StatefulWidget {
  final RepeatType selectedType;
  final List<int>? selectedDays;
  final int? selectedMonthDay;
  final Function(RepeatType) onTypeChanged;
  final Function(List<int>?) onDaysChanged;
  final Function(int?) onMonthDayChanged;

  const ScheduleSelector({
    super.key,
    required this.selectedType,
    this.selectedDays,
    this.selectedMonthDay,
    required this.onTypeChanged,
    required this.onDaysChanged,
    required this.onMonthDayChanged,
  });

  @override
  State<ScheduleSelector> createState() => _ScheduleSelectorState();
}

class _ScheduleSelectorState extends State<ScheduleSelector> {
  static const List<String> weekDays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'التكرار',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A5F),
          ),
        ),
        const SizedBox(height: 12),

        // Repeat Type Selector
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!, width: 1.5),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: RepeatType.values.map((type) {
              return RadioListTile<RepeatType>(
                title: Text(type.arabicName),
                value: type,
                groupValue: widget.selectedType,
                onChanged: (value) {
                  if (value != null) {
                    widget.onTypeChanged(value);
                    // Reset selections when type changes
                    if (value != RepeatType.specificDays &&
                        value != RepeatType.weekly) {
                      widget.onDaysChanged(null);
                    }
                    if (value != RepeatType.monthly) {
                      widget.onMonthDayChanged(null);
                    }
                  }
                },
                activeColor: const Color(0xFF06B6D4),
              );
            }).toList(),
          ),
        ),

        // Show day selector for weekly or specific days
        if (widget.selectedType == RepeatType.weekly ||
            widget.selectedType == RepeatType.specificDays) ...[
          const SizedBox(height: 16),
          Text(
            widget.selectedType == RepeatType.weekly
                ? 'اختر اليوم (يوم واحد فقط - مثلاً كل سبت)'
                : 'اختر الأيام (يمكنك اختيار أكثر من يوم)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (index) {
              final dayNumber = index + 1;
              final isSelected =
                  widget.selectedDays?.contains(dayNumber) ?? false;

              return widget.selectedType == RepeatType.weekly
                  ? ChoiceChip(
                      label: Text(weekDays[index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          // For weekly: only one day allowed
                          widget.onDaysChanged([dayNumber]);
                        } else {
                          widget.onDaysChanged(null);
                        }
                      },
                      selectedColor: const Color(0xFF06B6D4),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    )
                  : FilterChip(
                      label: Text(weekDays[index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        final currentDays = List<int>.from(
                          widget.selectedDays ?? [],
                        );
                        if (selected) {
                          currentDays.add(dayNumber);
                        } else {
                          currentDays.remove(dayNumber);
                        }
                        currentDays.sort();
                        widget.onDaysChanged(
                          currentDays.isEmpty ? null : currentDays,
                        );
                      },
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF06B6D4).withOpacity(0.3),
                      checkmarkColor: const Color(0xFF06B6D4),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    );
            }),
          ),
        ],

        // Show day selector for monthly
        if (widget.selectedType == RepeatType.monthly) ...[
          const SizedBox(height: 16),
          const Text(
            'اليوم من الشهر',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!, width: 1.5),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonFormField<int>(
              value: widget.selectedMonthDay,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: List.generate(31, (index) {
                final day = index + 1;
                return DropdownMenuItem(value: day, child: Text('يوم $day'));
              }),
              onChanged: (value) => widget.onMonthDayChanged(value),
              hint: const Text('اختر اليوم'),
            ),
          ),
        ],
      ],
    );
  }
}
