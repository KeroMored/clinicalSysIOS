import 'package:flutter/material.dart';
import '../../data/models/subscription_settings_model.dart';
import '../../data/models/payment_record_model.dart';

class AddPaymentDialog extends StatefulWidget {
  final SubscriptionSettingsModel settings;
  final String placeName;
  final Function(double amount, PaymentType type, DateTime date, String? notes)
  onSubmit;

  const AddPaymentDialog({
    super.key,
    required this.settings,
    required this.placeName,
    required this.onSubmit,
  });

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  PaymentType _selectedType = PaymentType.monthly;
  late TextEditingController _amountController;
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _useCustomAmount = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.settings.monthlyPrice.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTypeChanged(PaymentType? type) {
    if (type != null) {
      setState(() {
        _selectedType = type;
        if (!_useCustomAmount) {
          switch (type) {
            case PaymentType.monthly:
              _amountController.text = widget.settings.monthlyPrice
                  .toStringAsFixed(0);
              break;
            case PaymentType.yearly:
              _amountController.text = widget.settings.yearlyPrice
                  .toStringAsFixed(0);
              break;
            case PaymentType.custom:
              _useCustomAmount = true;
              break;
          }
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى إدخال مبلغ صحيح')));
      return;
    }

    widget.onSubmit(
      amount,
      _selectedType,
      _selectedDate,
      _notesController.text.isEmpty ? null : _notesController.text,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.payments,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تسجيل دفعة جديدة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.placeName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Payment Type Selection
              const Text(
                'نوع الاشتراك',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeChip(
                      PaymentType.monthly,
                      'شهري',
                      '${widget.settings.monthlyPrice.toStringAsFixed(0)} ج.م',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeChip(
                      PaymentType.yearly,
                      'سنوي',
                      '${widget.settings.yearlyPrice.toStringAsFixed(0)} ج.م',
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeChip(
                      PaymentType.custom,
                      'مخصص',
                      '',
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Amount
              Row(
                children: [
                  const Text(
                    'المبلغ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Switch(
                    value: _useCustomAmount,
                    onChanged: (value) =>
                        setState(() => _useCustomAmount = value),
                    activeColor: Colors.orange,
                  ),
                  const Text('مبلغ مخصص', style: TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                enabled:
                    _useCustomAmount || _selectedType == PaymentType.custom,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  suffixText: 'ج.م',
                  filled: true,
                  fillColor:
                      (_useCustomAmount || _selectedType == PaymentType.custom)
                      ? Colors.white
                      : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Date
              const Text(
                'تاريخ الدفع',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Notes
              const Text(
                'ملاحظات (اختياري)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'أضف ملاحظة...',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check),
                      label: const Text('تسجيل الدفع'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(
    PaymentType type,
    String label,
    String price,
    Color color,
  ) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => _onTypeChanged(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
            if (price.isNotEmpty)
              Text(
                price,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? color : Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
