import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart' as intl;
import 'package:clinicalsystem/core/theme/app_theme.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';
import '../../data/repositories/pharmacy_repository.dart';
import 'pharmacy_details_screen.dart';
import '../../../clinic/presentation/screens/clinic_details_screen.dart';
import '../../../clinic/data/repositories/clinic_repository.dart';
import '../../../gym/presentation/pages/gym_details_screen.dart';
import '../../../gym/data/repositories/gym_repository.dart';
import '../../../medical_supply/presentation/screens/medical_supply_details_screen.dart';
import '../../../medical_supply/data/repositories/medical_supply_repository.dart';

/// شاشة تفاصيل العرض الموحدة - تعمل مع جميع أنواع العروض (صيدليات، عيادات، جيم، مستلزمات طبية)
class OfferDetailsScreen extends StatefulWidget {
  final String offerId;
  final String collectionName; // 'offers', 'clinic_offers', 'gym_offers', 'medical_supply_offers'

  const OfferDetailsScreen({
    super.key,
    required this.offerId,
    required this.collectionName,
  });

  @override
  State<OfferDetailsScreen> createState() => _OfferDetailsScreenState();
}

class _OfferDetailsScreenState extends State<OfferDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _offerData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOfferData();
    _incrementViewsCount();
  }

  Future<void> _loadOfferData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.offerId)
          .get();

      if (!doc.exists) {
        setState(() {
          _errorMessage = 'العرض غير موجود';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _offerData = doc.data();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء تحميل البيانات';
        _isLoading = false;
      });
    }
  }

  Future<void> _incrementViewsCount() async {
    try {
      await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.offerId)
          .update({'viewsCount': FieldValue.increment(1)});
    } catch (e) {
      // Silent failure - لا نريد إيقاف العرض بسبب فشل زيادة العداد
      print('❌ Error incrementing views count: $e');
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return intl.DateFormat('dd/MM/yyyy', 'ar').format(date);
    }
  }

  String _formatWhatsAppNumber(String input) {
    String n = input.trim();
    if (n.startsWith('+')) n = n.substring(1);
    if (n.startsWith('20')) return n;
    return '20$n';
  }

  Future<void> _openWhatsApp(BuildContext context, String sourceId) async {
    try {
      if (widget.collectionName != 'offers') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('واتساب متاح فقط لعروض الصيدليات حالياً'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final pharmacyRepo = PharmacyRepository();
      final pharmacy = await pharmacyRepo.getPharmacyById(sourceId);

      if (pharmacy.whatsapp.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('رقم الواتساب غير متوفر'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final formatted = _formatWhatsAppNumber(pharmacy.whatsapp);
      final title = _offerData?['title'] ?? '';
      final description = _offerData?['description'] ?? '';
      final message =
          'مرحباً 👋\nأنا مهتم بالعرض الخاص بـ [ $title ]\n [ $description ]\n\nهل العرض لا زال متاحاً؟';
      final url =
          'https://wa.me/$formatted?text=${Uri.encodeComponent(message)}';

      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw Exception('فشل فتح تطبيق واتساب');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _makePhoneCall(BuildContext context, String sourceId) async {
    try {
      if (widget.collectionName != 'offers') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('الاتصال متاح فقط لعروض الصيدليات حالياً'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final pharmacyRepo = PharmacyRepository();
      final pharmacy = await pharmacyRepo.getPharmacyById(sourceId);

      if (pharmacy.phones.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('رقم الهاتف غير متوفر'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final launchUri = Uri(scheme: 'tel', path: pharmacy.phones[0]);
      final launched = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw Exception('فشل فتح تطبيق الاتصال');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToSourceDetails(BuildContext context) async {
    if (_offerData == null) return;

    String sourceId = '';
    if (widget.collectionName == 'offers') {
      sourceId = _offerData!['pharmacyId'] ?? '';
    } else if (widget.collectionName == 'clinic_offers') {
      sourceId = _offerData!['clinicId'] ?? '';
    } else if (widget.collectionName == 'gym_offers') {
      sourceId = _offerData!['gymId'] ?? '';
    } else if (widget.collectionName == 'medical_supply_offers') {
      sourceId = _offerData!['supplyId'] ?? '';
    }

    if (sourceId.isEmpty) return;

    try {
      if (widget.collectionName == 'offers') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PharmacyDetailsScreen(pharmacyId: sourceId),
          ),
        );
      } else if (widget.collectionName == 'clinic_offers') {
        // جلب بيانات العيادة أولاً
        final clinicRepo = ClinicRepository();
        final clinic = await clinicRepo.getClinicById(sourceId);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClinicDetailsScreen(clinic: clinic),
            ),
          );
        }
      } else if (widget.collectionName == 'gym_offers') {
        final gym = await GymRepository().getGymById(sourceId);
        if (gym != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GymDetailsScreen(gym: gym),
            ),
          );
        }
      } else if (widget.collectionName == 'medical_supply_offers') {
        final supply = await MedicalSupplyRepository().getMedicalSupplyById(sourceId);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MedicalSupplyDetailsScreen(supply: supply),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء فتح التفاصيل: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFullScreenImage(BuildContext context, int initialIndex) {
    final images = _offerData?['images'] ?? [];
    if (images.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageViewerPage(
          images: List<String>.from(images),
          initialIndex: initialIndex,
          offerId: widget.offerId,
        ),
      ),
    );
  }

  IconData _getSourceIcon() {
    if (widget.collectionName == 'offers') return Icons.local_pharmacy_rounded;
    if (widget.collectionName == 'clinic_offers')
      return Icons.local_hospital_rounded;
    if (widget.collectionName == 'gym_offers')
      return Icons.fitness_center_rounded;
    return Icons.medical_services_rounded;
  }

  String _getSourceTypeLabel() {
    if (widget.collectionName == 'offers') return 'صيدلية';
    if (widget.collectionName == 'clinic_offers') return 'عيادة';
    if (widget.collectionName == 'gym_offers') return 'جيم';
    return 'مستلزمات طبية';
  }

  Color _getSourceColor() {
    if (widget.collectionName == 'offers') return AppTheme.secondaryColor;
    if (widget.collectionName == 'clinic_offers')
      return const Color(0xFF0B8293);
    if (widget.collectionName == 'gym_offers')
      return const Color(0xFF0EA5A4);
    return const Color(0xFFE91E63);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: _isLoading
            ? const Center(child: AppLoadingIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      // AppBar
                      SliverAppBar(
                        toolbarHeight: 56,
                        expandedHeight: 0,
                        pinned: true,
                        elevation: 0,
                        scrolledUnderElevation: 0,
                        backgroundColor: Colors.white,
                        surfaceTintColor: Colors.white,
                        foregroundColor: const Color(0xFF0F172A),
                        leading: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: Color(0xFF0F172A),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        title: const Text(
                          'تفاصيل العرض',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                        centerTitle: true,
                        bottom: const PreferredSize(
                          preferredSize: Size.fromHeight(1),
                          child: Divider(
                            height: 1,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),

                      // محتوى الشاشة
                      SliverToBoxAdapter(
                        child: _buildContent(context),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final images = _offerData?['images'] ?? [];
    final title = _offerData?['title'] ?? '';
    final description = _offerData?['description'] ?? '';
    final notes = _offerData?['notes'] ?? '';
    
    String sourceName = '';
    if (widget.collectionName == 'offers') {
      sourceName = _offerData?['pharmacyName'] ?? '';
    } else if (widget.collectionName == 'clinic_offers') {
      sourceName = _offerData?['doctorName'] ?? '';
    } else if (widget.collectionName == 'gym_offers') {
      sourceName = _offerData?['gymName'] ?? '';
    } else if (widget.collectionName == 'medical_supply_offers') {
      sourceName = _offerData?['supplyName'] ?? '';
    }
    
    final createdAtTimestamp = _offerData?['createdAt'];
    final createdAt = createdAtTimestamp != null
        ? (createdAtTimestamp as Timestamp).toDate()
        : null;

    String sourceId = '';
    if (widget.collectionName == 'offers') {
      sourceId = _offerData?['pharmacyId'] ?? '';
    } else if (widget.collectionName == 'clinic_offers') {
      sourceId = _offerData?['clinicId'] ?? '';
    } else if (widget.collectionName == 'gym_offers') {
      sourceId = _offerData?['gymId'] ?? '';
    } else if (widget.collectionName == 'medical_supply_offers') {
      sourceId = _offerData?['supplyId'] ?? '';
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الصورة الرئيسية
          if (images.isNotEmpty)
            GestureDetector(
              onTap: () => _showFullScreenImage(context, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.network(
                      images[0],
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 240,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.local_offer,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    // Source Badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getSourceIcon(),
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getSourceTypeLabel(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (images.length > 1)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.photo_library,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${images.length} صور',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'اضغط لتكبير الصورة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (images.isNotEmpty) const SizedBox(height: 14),

          // صور أفقية متعددة (إن وجدت)
          if (images.length > 1) ...[
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length - 1,
                itemBuilder: (context, index) {
                  final actualIndex = index + 1;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: GestureDetector(
                      onTap: () => _showFullScreenImage(context, actualIndex),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          images[actualIndex],
                          width: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 120,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image_outlined,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
          ],

          // بطاقة المعلومات الرئيسية
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
                  // اسم المصدر (صيدلية/عيادة/جيم)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getSourceColor(),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getSourceIcon(),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _navigateToSourceDetails(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sourceName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _getSourceColor(),
                                ),
                              ),
                              if (createdAt != null)
                                Text(
                                  _formatDate(createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color.fromARGB(255, 7, 5, 44),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // عنوان العرض - عرض كامل بدون أي قيود
                  if (title.isNotEmpty) ...[
                    SelectableText(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A5F),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // وصف العرض - عرض كامل بدون أي قيود
                  if (description.isNotEmpty) ...[
                    SelectableText(
                      description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color.fromARGB(255, 12, 5, 33),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ملاحظات - عرض كامل بدون قيود
                  if (notes.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFBBF24),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFFF59E0B),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SelectableText(
                              notes,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFB45309),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // أزرار التواصل (للصيدليات فقط)
          if (widget.collectionName == 'offers') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openWhatsApp(context, sourceId),
                    icon: Icon(Icons.chat, size: 20),
                    label: const Text('واتساب'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
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
                    onPressed: () => _makePhoneCall(context, sourceId),
                    icon: const Icon(Icons.phone_rounded, size: 20),
                    label: const Text('اتصال'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A5F),
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
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// عارض الصور كامل الشاشة
class _ImageViewerPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String offerId;

  const _ImageViewerPage({
    required this.images,
    required this.initialIndex,
    required this.offerId,
  });

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage> {
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
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) => Center(
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Image.network(
                  widget.images[index],
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: AppLoadingIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // زر الإغلاق
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
          // مؤشر الصور المتعددة
          if (widget.images.length > 1)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
