import 'package:flutter/material.dart';

class RadiologyFilterChips extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const RadiologyFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFilterChip('الكل', 'all', Colors.teal),
          const SizedBox(width: 8),
          _buildFilterChip('قيد الانتظار', 'pending', Colors.orange),
          const SizedBox(width: 8),
          _buildFilterChip('مقبول', 'approved', Colors.green),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) => onFilterChanged(value),
      backgroundColor: Colors.white,
      selectedColor: color,
      side: BorderSide(color: color, width: 1.5),
      showCheckmark: false,
    );
  }
}
