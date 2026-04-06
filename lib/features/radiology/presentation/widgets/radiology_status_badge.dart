import 'package:flutter/material.dart';

class RadiologyStatusBadge extends StatelessWidget {
  final bool isApproved;

  const RadiologyStatusBadge({super.key, required this.isApproved});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            isApproved ? Icons.check_circle : Icons.pending,
            size: 14,
            color: isApproved ? Colors.green.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isApproved ? 'مقبول' : 'قيد الانتظار',
            style: TextStyle(
              fontSize: 11,
              color: isApproved
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
