import 'package:flutter/material.dart';

class MedicineNamesWidget extends StatelessWidget {
  final List<String> medicineNames;
  final Function(List<String>) onNamesChanged;

  const MedicineNamesWidget({
    super.key,
    required this.medicineNames,
    required this.onNamesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'أسماء الأدوية',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A5F),
              ),
            ),
            TextButton.icon(
              onPressed: () => _addMedicineName(context),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('إضافة دواء'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF06B6D4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
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
                  'يمكنك إضافة أكثر من دواء لنفس الموعد (مثلاً: أسبرين + فيتامين د)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        if (medicineNames.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF06B6D4).withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لم تقم بإضافة أي أدوية بعد',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
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
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: medicineNames.asMap().entries.map((entry) {
                final index = entry.key;
                final name = entry.value;
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: const Color(0xFF06B6D4),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  label: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                  backgroundColor: const Color(0xFF06B6D4).withOpacity(0.1),
                  deleteIcon: const Icon(Icons.close, size: 18, color: Color(0xFF06B6D4)),
                  onDeleted: () {
                    final newNames = List<String>.from(medicineNames);
                    newNames.removeAt(index);
                    onNamesChanged(newNames);
                  },
                  side: const BorderSide(color: Color(0xFF06B6D4), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Future<void> _addMedicineName(BuildContext context) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.medication,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'إضافة دواء',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              textDirection: TextDirection.rtl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'اسم الدواء',
                hintText: 'مثلاً: أسبرين',
                prefixIcon: const Icon(Icons.medical_services, color: Color(0xFF06B6D4)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال اسم الدواء';
                }
                if (medicineNames.contains(value.trim())) {
                  return 'هذا الدواء موجود بالفعل';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'إضافة',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      final newNames = List<String>.from(medicineNames);
      newNames.add(result);
      onNamesChanged(newNames);
    }
  }
}
