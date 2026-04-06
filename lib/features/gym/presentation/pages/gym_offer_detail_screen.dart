import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../data/repositories/gym_repository.dart';
import 'gym_details_screen.dart';

class GymOfferDetailScreen extends StatelessWidget {
  final String offerId;
  final String gymId;
  final String gymName;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime? createdAt;
  final double? discountPercentage;
  final double? oldPrice;
  final double? newPrice;

  const GymOfferDetailScreen({
    super.key,
    required this.offerId,
    required this.gymId,
    required this.gymName,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.createdAt,
    required this.discountPercentage,
    required this.oldPrice,
    required this.newPrice,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) return 'الآن';
        return 'منذ ${difference.inMinutes} دقيقة';
      }
      return 'منذ ${difference.inHours} ساعة';
    }

    if (difference.inDays == 1) {
      return 'أمس';
    }

    if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    }

    return intl.DateFormat('yyyy/MM/dd').format(date);
  }

  String _formatPrice(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  Future<void> _openGymProfile(BuildContext context) async {
    if (gymId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('بيانات الجيم غير متاحة حالياً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final gym = await GymRepository().getGymById(gymId);
      if (!context.mounted) {
        return;
      }

      if (gym == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن العثور على بيانات الجيم'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GymDetailsScreen(gym: gym)),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء فتح تفاصيل الجيم: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shownPrice = newPrice ?? oldPrice;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: const Color(0xFF0F172A),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'تفاصيل العرض',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (imageUrl.trim().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFE2E8F0),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 40,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (imageUrl.trim().isNotEmpty) const SizedBox(height: 14),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.trim().isEmpty ? 'عرض جيم' : title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.fitness_center_rounded,
                          size: 18,
                          color: Color(0xFF0EA5A4),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            gymName.trim().isEmpty ? 'جيم' : gymName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0EA5A4),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (discountPercentage != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB91C1C),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'خصم %${discountPercentage!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (description.trim().isNotEmpty)
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF334155),
                          height: 1.55,
                        ),
                      )
                    else
                      const Text(
                        'لا يوجد وصف إضافي لهذا العرض.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    if (shownPrice != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (oldPrice != null &&
                              newPrice != null &&
                              newPrice! < oldPrice!)
                            Text(
                              'ج.م ${_formatPrice(oldPrice!)}',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          if (oldPrice != null &&
                              newPrice != null &&
                              newPrice! < oldPrice!)
                            const SizedBox(width: 10),
                          Text(
                            'ج.م ${_formatPrice(shownPrice)}',
                            style: const TextStyle(
                              color: Color(0xFF0B7285),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              child: ElevatedButton.icon(
                onPressed: () => _openGymProfile(context),
                icon: const Icon(Icons.fitness_center_rounded),
                label: const Text(
                  'عرض صفحة الجيم',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
