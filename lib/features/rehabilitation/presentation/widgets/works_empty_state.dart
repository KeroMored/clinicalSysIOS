import 'package:flutter/material.dart';

class WorksEmptyState extends StatelessWidget {
  const WorksEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا يوجد محتوى متاح حالياً',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
