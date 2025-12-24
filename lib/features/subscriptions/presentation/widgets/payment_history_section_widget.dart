import 'package:flutter/material.dart';
import '../../data/models/payment_record_model.dart';
import '../widgets/payment_history_list.dart';

class PaymentHistorySectionWidget extends StatelessWidget {
  final List<PaymentRecordModel> payments;
  final Function(PaymentRecordModel) onDeletePayment;

  const PaymentHistorySectionWidget({
    super.key,
    required this.payments,
    required this.onDeletePayment,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'سجل الدفع',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${payments.length} دفعة',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PaymentHistoryList(
            payments: payments,
            onDeletePayment: onDeletePayment,
          ),
        ],
      ),
    );
  }
}
