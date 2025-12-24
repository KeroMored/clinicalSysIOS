import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../data/repositories/pharmacy_repository.dart';
import '../screens/pharmacy_details_screen.dart';

class OfferCard extends StatelessWidget {
  final String offerId;
  final String pharmacyId;
  final String pharmacyName;
  final String title;
  final String description;
  final String notes;
  final List<String> images;
  final DateTime? createdAt;
  final bool isOwnerView; // لإظهار menu button في لوحة التحكم فقط
  final bool isActive; // حالة العرض (متاح/مخفي)

  const OfferCard({
    super.key,
    required this.offerId,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.title,
    required this.description,
    required this.notes,
    required this.images,
    this.createdAt,
    this.isOwnerView = false, // افتراضياً للمستخدمين العاديين
    this.isActive = true, // افتراضياً العرض متاح
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'الآن';
        }
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
    n = n.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (n.startsWith('+')) n = n.substring(1);
    if (n.startsWith('00')) n = n.substring(2);
    if (n.startsWith('0')) n = n.substring(1);
    n = n.replaceAll(RegExp(r'[^0-9]'), '');
    return n;
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    try {
      if (pharmacyId.isEmpty) {
        throw Exception('معرف الصيدلية غير متوفر');
      }

      final pharmacyRepo = PharmacyRepository();
      final pharmacy = await pharmacyRepo.getPharmacyById(pharmacyId);
      
      if (pharmacy.whatsapp.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('رقم الواتساب غير متوفر لهذه الصيدلية'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final formatted = _formatWhatsAppNumber(pharmacy.whatsapp);
      if (formatted.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('رقم واتساب غير صحيح'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      final message = 'مرحباً 👋\nأنا مهتم بالعرض الخاص بـ [ $title ]\n [ $description ]\n\nهل العرض لا زال متاحاً؟';
      final url = 'https://wa.me/$formatted?text=${Uri.encodeComponent(message)}';
      
      final uri = Uri.parse(url);
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        throw Exception('فشل فتح تطبيق واتساب');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    try {
      if (pharmacyId.isEmpty) {
        throw Exception('معرف الصيدلية غير متوفر');
      }

      final pharmacyRepo = PharmacyRepository();
      final pharmacy = await pharmacyRepo.getPharmacyById(pharmacyId);
      
      if (pharmacy.phone.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('رقم الهاتف غير متوفر لهذه الصيدلية'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final Uri launchUri = Uri(
        scheme: 'tel',
        path: pharmacy.phone,
      );
      
      bool launched = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        throw Exception('فشل فتح تطبيق الاتصال');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: !isActive ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: !isActive 
            ? Border.all(color: Colors.grey[400]!, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Images Section (if available) - مصغر
              if (images.isNotEmpty) _buildCompactImagesSection(),

              // Content Section - مصغر
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Pharmacy Name Header - مصغر
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PharmacyDetailsScreen(
                          pharmacyId: pharmacyId,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00BCD4), Color(0xFF4DD0E1)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_pharmacy_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pharmacyName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A5F),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (createdAt != null)
                              Text(
                                _formatDate(createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Menu button - يظهر فقط في لوحة التحكم
                      if (isOwnerView)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onSelected: (value) {
                            if (value == 'toggle') {
                              _toggleOfferVisibility(context);
                            } else if (value == 'delete') {
                              _deleteOffer(context);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(
                                    isActive ? Icons.visibility_off : Icons.visibility,
                                    size: 20,
                                    color: isActive ? Colors.orange : Colors.green,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(isActive ? 'إخفاء العرض' : 'إظهار العرض'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text('حذف العرض'),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Title
                if (title.isNotEmpty) ...[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],

                // Description
                if (description.isNotEmpty) ...[
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],

                // Notes
                if (notes.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFBBF24), width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            notes,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB45309),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Contact Buttons - Only for non-owners - مصغرة
                if (!isOwnerView) ...[
                  const Divider(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openWhatsApp(context),
                          icon: Icon(MdiIcons.whatsapp, size: 16),
                          label: const Text('واتساب', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _makePhoneCall(context),
                          icon: const Icon(Icons.phone_rounded, size: 16),
                          label: const Text('اتصال', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A5F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      // Badge للعروض المخفية - مصغر
      if (!isActive && isOwnerView)
        Positioned(
          top: 6,
          left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_off_rounded, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  'مخفي',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildCompactImagesSection() {
    final imageWidget = images.length == 1
        ? _buildCompactSingleImage()
        : _buildCompactMultipleImages();
    
    if (!isActive) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.grey.withOpacity(0.5),
          BlendMode.saturation,
        ),
        child: imageWidget,
      );
    }
    
    return imageWidget;
  }

  Widget _buildCompactSingleImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Image.network(
        images[0],
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[300]!, Colors.grey[200]!],
              ),
            ),
            child: Icon(Icons.image_outlined, size: 48, color: Colors.grey[500]),
          );
        },
      ),
    );
  }

  Widget _buildCompactMultipleImages() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                images[index],
                width: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[300]!, Colors.grey[200]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.image_outlined, size: 40, color: Colors.grey[500]),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // Toggle offer visibility (show/hide)
  void _toggleOfferVisibility(BuildContext context) {
    final newStatus = !isActive;
    final actionText = newStatus ? 'إظهار' : 'إخفاء';
    final confirmText = newStatus 
        ? 'هل أنت متأكد من إظهار هذا العرض؟\nسيصبح متاحاً للعملاء.'
        : 'هل أنت متأكد من إخفاء هذا العرض؟\nسيتم إخفاؤه من العملاء ويمكنك إعادة تفعيله لاحقاً.';
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$actionText العرض'),
        content: Text(confirmText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await FirebaseFirestore.instance
                    .collection('offers')
                    .doc(offerId)
                    .update({'isActive': newStatus});
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم ${actionText} العرض بنجاح'),
                      backgroundColor: newStatus ? Colors.green : Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('حدث خطأ: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  // Delete offer permanently
  void _deleteOffer(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف العرض'),
        content: const Text('هل أنت متأكد من حذف هذا العرض نهائياً؟\nلا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await FirebaseFirestore.instance
                    .collection('offers')
                    .doc(offerId)
                    .delete();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف العرض بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('حدث خطأ: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
