import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/medicine_offer_model.dart';
import '../../../pharmacy/presentation/screens/pharmacy_details_screen.dart';
import '../../../pharmacy/data/repositories/pharmacy_repository.dart';
import '../../../pharmacy/presentation/cubit/pharmacy_cubit.dart';

class MedicineOfferDetailScreen extends StatelessWidget {
  final MedicineOfferModel offer;

  const MedicineOfferDetailScreen({super.key, required this.offer});

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
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return intl.DateFormat('yyyy/MM/dd').format(date);
    }
  }

  String _formatWhatsAppNumber(String input) {
    String n = input.trim();
    if (n.startsWith('+')) n = n.substring(1);
    if (n.startsWith('20')) return n;
    return '20$n';
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    try {
      final pharmacyRepo = PharmacyRepository();
      final pharmacy = await pharmacyRepo.getPharmacyById(offer.pharmacyId);

      if (pharmacy.whatsapp.isNotEmpty) {
        final formatted = _formatWhatsAppNumber(pharmacy.whatsapp);
        final message =
            'مرحباً 👋\nأنا مهتم بالعرض الخاص بـ *${offer.medicineName}*\nالسعر: ${offer.price} جنيه\n\nهل العرض لا زال متاحاً؟';
        final url =
            'https://wa.me/$formatted?text=${Uri.encodeComponent(message)}';
        try {
          final launched = await launchUrl(Uri.parse(url));
          if (!launched) throw 'Could not launch WhatsApp';
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('تعذر فتح واتساب')));
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('رقم الواتساب غير متوفر')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    }
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    try {
      final pharmacyRepo = PharmacyRepository();
      final pharmacy = await pharmacyRepo.getPharmacyById(offer.pharmacyId);

      if (pharmacy.phones.isNotEmpty) {
        final launchUri = Uri(scheme: 'tel', path: pharmacy.phones[0]);
        try {
          await launchUrl(launchUri);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('تعذر الاتصال')));
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('رقم الهاتف غير متوفر')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    }
  }

  void _navigateToPharmacyDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => PharmacyCubit(PharmacyRepository()),
          child: PharmacyDetailsScreen(pharmacyId: offer.pharmacyId),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: CustomScrollView(
          slivers: [
            // صورة مع AppBar شفاف فوقها
            SliverAppBar(
              expandedHeight:
                  offer.imageUrl != null && offer.imageUrl!.isNotEmpty
                  ? 280
                  : 0,
              pinned: true,
              backgroundColor: const Color(0xFF1A5F7A),
              foregroundColor: Colors.white,
              flexibleSpace:
                  offer.imageUrl != null && offer.imageUrl!.isNotEmpty
                  ? FlexibleSpaceBar(
                      background: GestureDetector(
                        onTap: () =>
                            _showFullScreenImage(context, offer.imageUrl!),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              offer.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.medication,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            // تدرج لتحسين قراءة AppBar
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.4),
                                    Colors.transparent,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            // أيقونة تكبير الصورة
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.zoom_in,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'اضغط لتكبير الصورة',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
              title: const Text(
                'تفاصيل العرض',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            // محتوى التفاصيل
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // بطاقة المعلومات الأساسية
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // اسم الدواء
                            Text(
                              offer.medicineName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A5F7A),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // التصنيف
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                offer.category,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // السعر والكمية
                            Row(
                              children: [
                                Expanded(
                                  child: _InfoChip(
                                    icon: Icons.attach_money,
                                    label: '${offer.price} جنيه',
                                    color: const Color(0xFF57CC99),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _InfoChip(
                                    icon: Icons.inventory_2,
                                    label: 'متوفر: ${offer.quantity}',
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // اسم الصيدلية والتاريخ
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_pharmacy,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        offer.pharmacyName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                      Text(
                                        _formatDate(offer.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // وصف العرض (إذا موجود)
                    if (offer.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
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
                              const Row(
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    size: 18,
                                    color: Color(0xFF1A5F7A),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'تفاصيل العرض',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A5F7A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                offer.description,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF444444),
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // أزرار التواصل
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openWhatsApp(context),
                            icon: Icon(Icons.chat, size: 20),
                            label: const Text('واتساب'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _makePhoneCall(context),
                            icon: const Icon(Icons.phone, size: 20),
                            label: const Text('اتصال'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A5F7A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToPharmacyDetails(context),
                        icon: const Icon(Icons.info_outline, size: 20),
                        label: const Text('تفاصيل الصيدلية'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1A5F7A),
                          side: const BorderSide(color: Color(0xFF1A5F7A)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
