import 'package:flutter/material.dart';

class NotesSectionWidget extends StatelessWidget {
  final String notes;
  final VoidCallback onEdit;

  const NotesSectionWidget({
    super.key,
    required this.notes,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note_alt, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'الملاحظات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('تعديل'),
                ),
              ],
            ),
            const Divider(),
            Text(
              notes.isEmpty ? 'لا توجد ملاحظات' : notes,
              style: TextStyle(
                color: notes.isEmpty ? Colors.grey : Colors.black87,
                fontStyle: notes.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
