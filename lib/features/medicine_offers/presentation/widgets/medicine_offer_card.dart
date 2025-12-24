import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/medicine_offer_model.dart';
import '../../../pharmacy/presentation/screens/pharmacy_details_screen.dart';
import '../../../pharmacy/data/repositories/pharmacy_repository.dart';
import '../../../pharmacy/presentation/cubit/pharmacy_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MedicineOfferCard extends StatelessWidget {
  final MedicineOfferModel offer;

  const MedicineOfferCard({
    super.key,
    required this.offer,
  });

  String _formatWhatsAppNumber(String input) {
    // Keep digits and '+' only initially
    String n = input.trim();
    // Remove all spaces, dashes, and parentheses
    n = n.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Remove leading '+'
    if (n.startsWith('+')) n = n.substring(1);
    // Convert leading '00' international prefix to just country code
    if (n.startsWith('00')) n = n.substring(2);
    // Remove a single leading '0' for local numbers as requested
    if (n.startsWith('0')) n = n.substring(1);
    // Finally, strip any remaining non-digits to be safe
    n = n.replaceAll(RegExp(r'[^0-9]'), '');
    return n;
  }

  // فتح واتساب
  Future<void> _openWhatsApp(BuildContext context, String pharmacyId) async {
    try {
      // جلب بيانات الصيدلية للحصول على رقم الواتساب
      final pharmacyRepo = PharmacyRepository();
      final pharmacy = await pharmacyRepo.getPharmacyById(pharmacyId);
      
      if (pharmacy.whatsapp.isNotEmpty) {
        final formatted = _formatWhatsAppNumber(pharmacy.whatsapp);
        if (formatted.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('رقم واتساب غير صحيح')),
            );
          }
          return;
        }
        
        final message = 'مرحباً 👋\nأنا مهتم بالعرض الخاص بـ *${offer.medicineName}*\nالسعر: ${offer.price} جنيه\n\nهل العرض لا زال متاحاً؟';
        final url = 'https://wa.me/$formatted?text=${Uri.encodeComponent(message)}';
        
        try {
          bool launched = await launchUrl(Uri.parse(url));
          if (!launched) {
            throw 'Could not launch WhatsApp';
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تعذر فتح واتساب')),
            );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  // الاتصال بالصيدلية
  Future<void> _makePhoneCall(BuildContext context, String pharmacyId) async {
    try {
      // جلب بيانات الصيدلية للحصول على رقم التليفون
      final pharmacyRepo = PharmacyRepository();
      final pharmacy = await pharmacyRepo.getPharmacyById(pharmacyId);
      
      if (pharmacy.phone.isNotEmpty) {
        final Uri launchUri = Uri(
          scheme: 'tel',
          path: pharmacy.phone,
        );
        
        try {
          await launchUrl(launchUri);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تعذر الاتصال')),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('رقم الهاتف غير متوفر')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  // الذهاب لصفحة تفاصيل الصيدلية
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة الدواء
          if (offer.imageUrl != null && offer.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                offer.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.medication, size: 80, color: Colors.grey),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // اسم الدواء
                Text(
                  offer.medicineName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A5F7A),
                  ),
                ),
                const SizedBox(height: 8),

                // اسم الصيدلية
                Row(
                  children: [
                    const Icon(Icons.local_pharmacy, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        offer.pharmacyName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // السعر والكمية
                Row(
                  children: [
                    // السعر
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF57CC99).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_money, size: 20, color: Color(0xFF57CC99)),
                          Text(
                            '${offer.price} جنيه',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF57CC99),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // الكمية المتاحة
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2, size: 18, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'متوفر: ${offer.quantity}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // الوصف
                if (offer.description.isNotEmpty)
                  Text(
                    offer.description,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // أزرار التواصل
                Row(
                  children: [
                    // زر واتساب
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openWhatsApp(context, offer.pharmacyId),
                        icon:  Icon(MdiIcons.whatsapp, size: 20),
                        label: const Text('واتساب'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // زر اتصال
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _makePhoneCall(context, offer.pharmacyId),
                        icon: const Icon(Icons.phone, size: 20),
                        label: const Text('اتصال'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A5F7A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // زر تفاصيل الصيدلية
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToPharmacyDetails(context),
                    icon: const Icon(Icons.info_outline, size: 20),
                    label: const Text('تفاصيل الصيدلية'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A5F7A),
                      side: const BorderSide(color: Color(0xFF1A5F7A)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
