import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/radiology_model.dart';
import '../cubit/radiology_cubit.dart';

class RadiologyApprovalButtons extends StatelessWidget {
  final RadiologyModel radiology;

  const RadiologyApprovalButtons({
    super.key,
    required this.radiology,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'إجراءات الموافقة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApproveDialog(context),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('موافقة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRejectDialog(context),
                    icon: const Icon(Icons.cancel),
                    label: const Text('رفض'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(BuildContext context) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('الموافقة على مركز الأشعة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('هل أنت متأكد من الموافقة على "${radiology.centerName}"؟'),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<RadiologyCubit>().approveRadiologyCenter(
                      radiology.id,
                      notes: notesController.text.isEmpty ? null : notesController.text,
                    );
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('موافقة'),
            ),
          ],
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('رفض مركز الأشعة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('هل أنت متأكد من رفض "${radiology.centerName}"؟'),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'سبب الرفض *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (notesController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال سبب الرفض')),
                  );
                  return;
                }
                context.read<RadiologyCubit>().rejectRadiologyCenter(
                      radiology.id,
                      notesController.text,
                    );
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('رفض'),
            ),
          ],
        );
      },
    );
  }
}
