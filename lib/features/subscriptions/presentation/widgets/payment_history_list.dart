import 'package:flutter/material.dart';
import '../../data/models/payment_record_model.dart';

class PaymentHistoryList extends StatelessWidget {
  final List<PaymentRecordModel> payments;
  final Function(PaymentRecordModel)? onDeletePayment;

  const PaymentHistoryList({
    super.key,
    required this.payments,
    this.onDeletePayment,
  });

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد سجلات دفع',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return _buildPaymentCard(context, payment);
      },
    );
  }

  Widget _buildPaymentCard(BuildContext context, PaymentRecordModel payment) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with amount and type
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
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
                      Text(
                        '${payment.amount.toStringAsFixed(0)} ج.م',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPaymentTypeColor(payment.paymentType).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          payment.paymentType.arabicName,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getPaymentTypeColor(payment.paymentType),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDeletePayment != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(context, payment),
                    tooltip: 'حذف',
                  ),
              ],
            ),
            const Divider(height: 20),

            // Date info
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.calendar_today,
                    label: 'تاريخ الدفع',
                    value: _formatDate(payment.paymentDate),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.event_available,
                    label: 'بداية الاشتراك',
                    value: _formatDate(payment.subscriptionStartDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.event_busy,
                    label: 'نهاية الاشتراك',
                    value: _formatDate(payment.subscriptionEndDate),
                    valueColor: payment.subscriptionEndDate.isBefore(DateTime.now())
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.timelapse,
                    label: 'المدة',
                    value: payment.durationText,
                  ),
                ),
              ],
            ),

            // Notes
            if (payment.notes != null && payment.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        payment.notes!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Recorded by info
            const SizedBox(height: 8),
            Text(
              'سجل بواسطة: ${payment.recordedBy} - ${_formatDateTime(payment.createdAt)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getPaymentTypeColor(PaymentType type) {
    switch (type) {
      case PaymentType.monthly:
        return Colors.blue;
      case PaymentType.yearly:
        return Colors.purple;
      case PaymentType.custom:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteConfirmation(BuildContext context, PaymentRecordModel payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف سجل الدفع'),
        content: Text(
          'هل أنت متأكد من حذف دفعة ${payment.amount.toStringAsFixed(0)} ج.م بتاريخ ${_formatDate(payment.paymentDate)}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDeletePayment?.call(payment);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
