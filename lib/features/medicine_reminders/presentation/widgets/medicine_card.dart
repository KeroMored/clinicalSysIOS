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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              // Top Row: Image, Name, Actions
              Row(
                children: [
                  // Medicine Image
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: medicine.imageUrl != null
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                            ),
                      image: medicine.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(medicine.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: medicine.imageUrl == null
                        ? const Icon(
                            Icons.medication,
                            color: Colors.white,
                            size: 32,
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  
                  // Medicine Name - Expanded to take full space
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display all medicine names
                        if (medicine.medicineNames.isEmpty)
                          const Text(
                            'دواء بدون اسم',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          )
                        else if (medicine.medicineNames.length == 1)
                          Text(
                            medicine.medicineNames.first,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A5F),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          // Multiple names - show them all with numbers
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: medicine.medicineNames.asMap().entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF06B6D4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${entry.key + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E3A5F),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 4),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: medicine.isActive
                                ? const Color(0xFF10B981).withOpacity(0.15)
                                : Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                medicine.isActive ? Icons.alarm_on : Icons.alarm_off,
                                size: 14,
                                color: medicine.isActive
                                    ? const Color(0xFF10B981)
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                medicine.isActive ? 'نشط' : 'متوقف',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: medicine.isActive
                                      ? const Color(0xFF10B981)
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Switch and Delete
                  Column(
                    children: [
                      Transform.scale(
                        scale: 0.85,
                        child: Switch(
                          value: medicine.isActive,
                          onChanged: (_) => onToggle(),
                          activeColor: const Color(0xFF10B981),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red[400],
                        iconSize: 20,
                        onPressed: onDelete,
                        tooltip: 'حذف',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              // Repeat Type with days if specificDays
              Row(
                children: [
                  Icon(
                    Icons.repeat,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _getRepeatTypeText(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
              
              // All Reminder Times - Full Width
              if (medicine.reminderTimes.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF06B6D4).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: medicine.reminderTimes.map((time) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF06B6D4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Color(0xFF06B6D4),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(time),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF06B6D4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Get repeat type text with day names for specificDays
  String _getRepeatTypeText() {
    if (medicine.repeatType == RepeatType.specificDays && 
        medicine.specificDays != null && 
        medicine.specificDays!.isNotEmpty) {
      final dayNames = medicine.specificDays!.map((day) => _getArabicDayName(day)).join(' و ');
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
