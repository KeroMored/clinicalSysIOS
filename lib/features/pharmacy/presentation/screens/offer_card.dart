import 'package:clinicalsystem/core/theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/repositories/pharmacy_repository.dart';
import '../screens/pharmacy_details_screen.dart';
import '../screens/pharmacy_offer_detail_screen.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

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
  final bool showViewsCount; // إظهار عدد المشاهدات
  final int viewsCount; // عدد المشاهدات
  final String category; // تصنيف العرض

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
    this.showViewsCount = false, // افتراضياً مخفي
    this.viewsCount = 0,
    this.category = 'عام',
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
    // خد الرقم زي ما هو وضيفله +20 فقط
    String n = input.trim();
    // لو بيبدأ بـ + شيله
    if (n.startsWith('+')) n = n.substring(1);
    // لو بيبدأ بـ 20 يبقى خلاص
    if (n.startsWith('20')) return '20$n';
    // ضيف +20 قدام الرقم
    return '20$n';
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

      final message =
          'مرحباً 👋\nأنا مهتم بالعرض الخاص بـ [ $title ]\n [ $description ]\n\nهل العرض لا زال متاحاً؟';
      final url =
          'https://wa.me/$formatted?text=${Uri.encodeComponent(message)}';

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

      if (pharmacy.phones.isEmpty) {
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
        path: pharmacy.phones[0], // استخدام أول رقم متاح
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
        border: Border.merge(
          Border(right: BorderSide(color: AppTheme.secondaryColor, width: 0.5)),
          Border(
            bottom: BorderSide(color: AppTheme.secondaryColor, width: 1.5),
          ),
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Images Section (if available) - مصغر
              if (images.isNotEmpty) _buildOfferMediaSection(),

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
                            builder: (context) =>
                                PharmacyDetailsScreen(pharmacyId: pharmacyId),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor,
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
                                    fontSize: 12,
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
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Menu button - يظهر فقط في لوحة التحكم
                          if (isOwnerView)
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.grey,
                              ),
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
                                        isActive
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        size: 20,
                                        color: isActive
                                            ? Colors.orange
                                            : Colors.green,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        isActive
                                            ? 'إخفاء العرض'
                                            : 'إظهار العرض',
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 12),
                                      Text('حذف العرض'),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Colors.grey,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Title + Description + Notes - الضغط عليها يفتح صفحة التفاصيل
                    GestureDetector(
                      onTap: () => _openOfferDetails(context),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Description
                          if (description.isNotEmpty) ...[
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color.fromARGB(255, 12, 8, 63),
                                height: 1.2,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                          ],

                          // Notes - تم إخفاؤها من الكارد (ظاهرة فقط في صفحة التفاصيل)
                        ],
                      ),
                    ), // GestureDetector
                    // Contact Buttons - Only for non-owners - مصغرة
                    if (!isOwnerView) ...[
                      //   const Divider(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openWhatsApp(context),
                              icon: Icon(FontAwesomeIcons.whatsapp, size: 16),
                              label: const Text(
                                'واتساب',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
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
                              label: const Text(
                                'اتصال',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.secondaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
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
                    Icon(
                      Icons.visibility_off_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
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

  Widget _buildOfferMediaSection() {
    final media = _buildCompactImagesSection();

    // بادج "عرض خاص" يظهر في واجهة المستخدم فقط
    if (isOwnerView || !isActive) {
      return media;
    }

    return Stack(
      children: [
        media,
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFD84315),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Text(
              'عرض خاص',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSingleImage() {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () => _openOfferDetails(context),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            child: Hero(
              tag: 'offer_image_${offerId}_0',
              child: Image.network(
                images[0],
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[100]!, Colors.grey[50]!],
                      ),
                    ),
                    child: Center(
                      child: AppLoadingIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.teal,
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[300]!, Colors.grey[200]!],
                      ),
                    ),
                    child: Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: Colors.grey[500],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactMultipleImages() {
    return SizedBox(
      height: 140,
      child: Builder(
        builder: (context) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: () => _openOfferDetails(context),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Hero(
                      tag: 'offer_image_${offerId}_$index',
                      child: Image.network(
                        images[index],
                        width: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 200,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.grey[100]!, Colors.grey[50]!],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: AppLoadingIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.teal,
                                ),
                                strokeWidth: 2.5,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.grey[300]!, Colors.grey[200]!],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: Colors.grey[500],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openOfferDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PharmacyOfferDetailScreen(
          offerId: offerId,
          pharmacyId: pharmacyId,
          pharmacyName: pharmacyName,
          title: title,
          description: description,
          notes: notes,
          images: images,
          createdAt: createdAt,
          category: category,
        ),
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
        content: const Text(
          'هل أنت متأكد من حذف هذا العرض نهائياً؟\nلا يمكن التراجع عن هذا الإجراء.',
        ),
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

  // Show full screen image viewer with Hero animation
  void _showImageViewer(
    BuildContext context,
    String imageUrl,
    int initialIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageViewerScreen(
          images: images,
          initialIndex: initialIndex,
          offerId: offerId,
        ),
      ),
    );
  }
}

// Full screen image viewer
class _ImageViewerScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String offerId;

  const _ImageViewerScreen({
    required this.images,
    required this.initialIndex,
    required this.offerId,
  });

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView for images
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: Hero(
                  tag: 'offer_image_${widget.offerId}_$index',
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: AppLoadingIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 48,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          // Top bar with close button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  if (widget.images.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Navigation arrows for multiple images
          if (widget.images.length > 1) ...[
            // Previous button
            if (_currentIndex > 0)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ),
              ),
            // Next button
            if (_currentIndex < widget.images.length - 1)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
