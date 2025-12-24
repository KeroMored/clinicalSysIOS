import 'package:flutter/material.dart';
import '../../data/models/subscribed_place_model.dart';

class SubscriptionStatusCardWidget extends StatelessWidget {
  final SubscribedPlaceModel place;

  const SubscriptionStatusCardWidget({
    super.key,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: place.isSubscriptionExpired
                ? [Colors.red[100]!, Colors.red[50]!]
                : [Colors.green[100]!, Colors.green[50]!],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: place.isSubscriptionExpired
                    ? Colors.red.withValues(alpha: 0.2)
                    : Colors.green.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                place.isSubscriptionExpired
                    ? Icons.cancel_outlined
                    : Icons.check_circle_outline,
                size: 32,
                color: place.isSubscriptionExpired ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.subscriptionEndDate != null
                        ? (place.isSubscriptionExpired
                            ? 'انتهى الاشتراك'
                            : 'الاشتراك فعال')
                        : 'لم يتم الاشتراك بعد',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          place.isSubscriptionExpired ? Colors.red : Colors.green,
                    ),
                  ),
                  if (place.subscriptionEndDate != null)
                    Text(
                      place.isSubscriptionExpired
                          ? 'انتهى في: ${_formatDate(place.subscriptionEndDate!)}'
                          : 'ينتهي في: ${_formatDate(place.subscriptionEndDate!)}',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${place.totalPaid.toStringAsFixed(0)} ج.م',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  '${place.paymentCount} دفعة',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
