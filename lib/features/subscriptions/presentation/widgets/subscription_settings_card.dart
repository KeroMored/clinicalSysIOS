import 'package:flutter/material.dart';
import '../../data/models/subscription_settings_model.dart';

class SubscriptionSettingsCard extends StatefulWidget {
  final SubscriptionSettingsModel settings;
  final Function(double monthlyPrice, double yearlyPrice) onSave;

  const SubscriptionSettingsCard({
    super.key,
    required this.settings,
    required this.onSave,
  });

  @override
  State<SubscriptionSettingsCard> createState() =>
      _SubscriptionSettingsCardState();
}

class _SubscriptionSettingsCardState extends State<SubscriptionSettingsCard> {
  late TextEditingController _monthlyController;
  late TextEditingController _yearlyController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _monthlyController = TextEditingController(
      text: widget.settings.monthlyPrice.toStringAsFixed(0),
    );
    _yearlyController = TextEditingController(
      text: widget.settings.yearlyPrice.toStringAsFixed(0),
    );
  }

  @override
  void didUpdateWidget(covariant SubscriptionSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _monthlyController.text = widget.settings.monthlyPrice.toStringAsFixed(0);
      _yearlyController.text = widget.settings.yearlyPrice.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _monthlyController.dispose();
    _yearlyController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
  }

  void _save() {
    final monthly = double.tryParse(_monthlyController.text) ?? 0;
    final yearly = double.tryParse(_yearlyController.text) ?? 0;

    if (monthly <= 0 || yearly <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى إدخال أسعار صحيحة')));
      return;
    }

    widget.onSave(monthly, yearly);
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إعدادات الاشتراك',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'تحديد أسعار الاشتراك الشهري والسنوي',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _toggleEdit,
                  icon: Icon(
                    _isEditing ? Icons.close : Icons.edit,
                    color: _isEditing ? Colors.red : Colors.grey,
                  ),
                  tooltip: _isEditing ? 'إلغاء' : 'تعديل',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Price inputs
            Row(
              children: [
                Expanded(
                  child: _buildPriceField(
                    controller: _monthlyController,
                    label: 'سعر الشهر',
                    icon: Icons.calendar_month,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPriceField(
                    controller: _yearlyController,
                    label: 'سعر السنة',
                    icon: Icons.calendar_today,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),

            // Save button
            if (_isEditing) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ التغييرات'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            // Last updated
            const SizedBox(height: 16),
            Center(
              child: Text(
                'آخر تحديث: ${_formatDate(widget.settings.updatedAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: _isEditing,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          decoration: InputDecoration(
            suffixText: 'ج.م',
            filled: true,
            fillColor: _isEditing
                ? Colors.white
                : color.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
