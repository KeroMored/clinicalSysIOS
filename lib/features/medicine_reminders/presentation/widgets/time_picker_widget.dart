import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

class TimePickerWidget extends StatelessWidget {
  final List<String> selectedTimes;
  final Function(List<String>) onTimesChanged;

  const TimePickerWidget({
    super.key,
    required this.selectedTimes,
    required this.onTimesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مواعيد التذكير',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF06B6D4).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF06B6D4),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'يمكنك إضافة أكثر من موعد لنفس الدواء (مثلاً: 9 صباحاً، 2 ظهراً، 9 مساءً)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (selectedTimes.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF06B6D4).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedTimes.map((time) {
                  return Chip(
                    label: Text(
                      _formatTimeTo12Hour(time),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF06B6D4),
                      ),
                    ),
                    backgroundColor: const Color(0xFF06B6D4).withOpacity(0.1),
                    deleteIcon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF06B6D4),
                    ),
                    onDeleted: () {
                      final newTimes = List<String>.from(selectedTimes);
                      newTimes.remove(time);
                      onTimesChanged(newTimes);
                    },
                    side: const BorderSide(
                      color: Color(0xFF06B6D4),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  );
                }).toList(),
              ),
            ),

          // Add Time Button
          Container(
            width: double.infinity,

            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _addTime(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_circle, size: 24),
              label: const Text(
                'إضافة المواعيد',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addTime(BuildContext context) async {
    int selectedHour = 9;
    int selectedMinute = 0;
    String selectedPeriod = 'ص'; // صباحاً

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: 350,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'اختر الموعد',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')} $selectedPeriod',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Time Pickers
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hour Picker
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: selectedHour - 1,
                            ),
                            itemExtent: 50,
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                selectedHour = index + 1;
                              });
                            },
                            children: List.generate(12, (index) {
                              return Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        const Text(
                          ':',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Minute Picker
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: selectedMinute ~/ 5,
                            ),
                            itemExtent: 50,
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                selectedMinute = index * 5;
                              });
                            },
                            children: List.generate(12, (index) {
                              final minute = index * 5;
                              return Center(
                                child: Text(
                                  minute.toString().padLeft(2, '0'),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // AM/PM Picker
                        SizedBox(
                          width: 80,
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: selectedPeriod == 'ص' ? 0 : 1,
                            ),
                            itemExtent: 50,
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                selectedPeriod = index == 0 ? 'ص' : 'م';
                              });
                            },
                            children: const [
                              Center(
                                child: Text(
                                  'ص',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  'م',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Buttons
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFF06B6D4)),
                            ),
                            child: const Text('إلغاء'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Convert to 24-hour format
                              int hour24 = selectedHour;
                              if (selectedPeriod == 'م' && selectedHour != 12) {
                                hour24 += 12;
                              } else if (selectedPeriod == 'ص' &&
                                  selectedHour == 12) {
                                hour24 = 0;
                              }

                              final timeString =
                                  '${hour24.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';

                              if (!selectedTimes.contains(timeString)) {
                                final newTimes = List<String>.from(
                                  selectedTimes,
                                );
                                newTimes.add(timeString);
                                newTimes.sort();
                                onTimesChanged(newTimes);
                              }

                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF06B6D4),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'إضافة',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimeTo12Hour(String time24) {
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
