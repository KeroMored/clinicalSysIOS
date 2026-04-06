import 'package:flutter/material.dart';
import '../../data/models/radiology_model.dart';

class RadiologyServicesCard extends StatelessWidget {
  final RadiologyModel radiology;

  const RadiologyServicesCard({super.key, required this.radiology});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الخدمات المتاحة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const Divider(),
            if (radiology.homeVisit)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home, size: 18, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'زيارة منزلية',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (radiology.services.isEmpty)
              const Center(child: Text('لا توجد خدمات'))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: radiology.services.map((service) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.deepPurple.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.deepPurple.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          service,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.deepPurple.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
