import 'package:flutter/material.dart';
import '../core/services/offer_sorting_service.dart';
import '../core/services/app_control_service.dart';
import '../features/medicine_offers/data/models/medicine_offer_model.dart';
import 'package:mallawicure/core/widgets/app_loading_indicator.dart';

/// ملف تجريبي يوضح كيفية استخدام نظام الترتيب الديناميكي
///
/// هذا الملف للأغراض التعليمية فقط ولن يتم استخدامه في الإنتاج
void main() {
  runApp(const DynamicSortingDemoApp());
}

class DynamicSortingDemoApp extends StatelessWidget {
  const DynamicSortingDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Sorting Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DemoHomeScreen(),
    );
  }
}

class DemoHomeScreen extends StatefulWidget {
  const DemoHomeScreen({super.key});

  @override
  State<DemoHomeScreen> createState() => _DemoHomeScreenState();
}

class _DemoHomeScreenState extends State<DemoHomeScreen> {
  final OfferSortingService _sortingService = OfferSortingService();
  final AppControlService _appControlService = AppControlService();

  List<MedicineOfferModel> _offers = [];
  List<MedicineOfferModel> _sortedOffers = [];
  bool _showViewsCount = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDemoData();
    _loadSettings();
  }

  /// تحميل الإعدادات من Firestore
  Future<void> _loadSettings() async {
    try {
      final settings = await _appControlService.getOffersSettings();
      setState(() {
        _showViewsCount = settings.showViewsCount;
      });
    } catch (e) {
      debugPrint('خطأ في تحميل الإعدادات: $e');
    }
  }

  /// إنشاء بيانات تجريبية
  void _loadDemoData() {
    setState(() {
      _offers = [
        MedicineOfferModel(
          id: '1',
          pharmacyId: 'pharmacy1',
          pharmacyName: 'صيدلية النور',
          medicineName: 'بانادول أقراص',
          quantity: 100,
          price: 25.0,
          description: 'مسكن للآلام وخافض للحرارة',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          isActive: true,
          viewsCount: 45,
          category: 'مسكنات',
        ),
        MedicineOfferModel(
          id: '2',
          pharmacyId: 'pharmacy1',
          pharmacyName: 'صيدلية الشفاء',
          medicineName: 'أموكسيل كبسولات',
          quantity: 50,
          price: 60.0,
          description: 'مضاد حيوي واسع المجال',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          isActive: true,
          viewsCount: 120,
          category: 'مضادات حيوية',
        ),
        MedicineOfferModel(
          id: '3',
          pharmacyId: 'pharmacy2',
          pharmacyName: 'صيدلية الحياة',
          medicineName: 'كونجستال أقراص',
          quantity: 75,
          price: 30.0,
          description: 'علاج البرد والإنفلونزا',
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
          isActive: true,
          viewsCount: 15,
          category: 'أدوية البرد',
        ),
        MedicineOfferModel(
          id: '4',
          pharmacyId: 'pharmacy3',
          pharmacyName: 'صيدلية العافية',
          medicineName: 'فيتامين د 5000',
          quantity: 200,
          price: 90.0,
          description: 'مكمل غذائي للعظام',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          isActive: true,
          viewsCount: 200,
          category: 'مكملات غذائية',
        ),
        MedicineOfferModel(
          id: '5',
          pharmacyId: 'pharmacy2',
          pharmacyName: 'صيدلية الأمل',
          medicineName: 'بروفين شراب',
          quantity: 30,
          price: 35.0,
          description: 'مسكن للأطفال',
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          isActive: true,
          viewsCount: 8,
          category: 'مسكنات',
        ),
        MedicineOfferModel(
          id: '6',
          pharmacyId: 'pharmacy1',
          pharmacyName: 'صيدلية السلام',
          medicineName: 'أوميجا 3',
          quantity: 150,
          price: 120.0,
          description: 'زيت السمك للقلب',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          isActive: true,
          viewsCount: 55,
          category: 'مكملات غذائية',
        ),
      ];
    });
  }

  /// تطبيق الترتيب الديناميكي
  void _applySorting() {
    setState(() {
      _isLoading = true;
    });

    // محاكاة تأخير الشبكة
    Future.delayed(const Duration(milliseconds: 500), () {
      final sorted = _sortingService.sortOffers(
        offers: _offers,
        pageNumber: 0,
        pageSize: _offers.length,
      );

      setState(() {
        _sortedOffers = sorted;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تطبيق الترتيب الديناميكي'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  /// إعادة تعيين الترتيب
  void _resetSorting() {
    setState(() {
      _sortedOffers = [];
      _sortingService.resetDiversityTracking();
    });
  }

  /// تبديل إظهار عدد المشاهدات
  Future<void> _toggleShowViewsCount() async {
    try {
      final newValue = !_showViewsCount;
      await _appControlService.updateShowViewsCount(newValue);

      setState(() {
        _showViewsCount = newValue;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newValue ? 'تم إظهار عدد المشاهدات' : 'تم إخفاء عدد المشاهدات',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayOffers = _sortedOffers.isEmpty ? _offers : _sortedOffers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تجربة الترتيب الديناميكي'),
        actions: [
          IconButton(
            icon: Icon(
              _showViewsCount ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: _toggleShowViewsCount,
            tooltip: 'إظهار/إخفاء عدد المشاهدات',
          ),
        ],
      ),
      body: Column(
        children: [
          // أزرار التحكم
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _applySorting,
                        icon: const Icon(Icons.shuffle),
                        label: const Text('تطبيق الترتيب الديناميكي'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _resetSorting,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _sortedOffers.isEmpty
                      ? 'الترتيب الحالي: افتراضي (حسب التاريخ)'
                      : 'الترتيب الحالي: ديناميكي (حسب النتيجة)',
                  style: TextStyle(
                    color: _sortedOffers.isEmpty ? Colors.grey : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // قائمة العروض
          Expanded(
            child: _isLoading
                ? const Center(child: AppLoadingIndicator())
                : ListView.builder(
                    itemCount: displayOffers.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final offer = displayOffers[index];
                      final originalIndex = _offers.indexOf(offer);
                      final positionChanged =
                          index != originalIndex && _sortedOffers.isNotEmpty;

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        color: positionChanged ? Colors.yellow.shade50 : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: positionChanged
                                ? Colors.orange
                                : Colors.blue,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            offer.medicineName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(offer.pharmacyName),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      offer.category,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                  if (_showViewsCount) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.visibility, size: 14),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${offer.viewsCount}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  const Icon(Icons.access_time, size: 14),
                                  const SizedBox(width: 2),
                                  Text(
                                    _getTimeAgo(offer.createdAt),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${offer.price} ج',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              if (positionChanged)
                                Icon(
                                  originalIndex > index
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // معلومات إضافية
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade200,
            child: Column(
              children: [
                const Text(
                  'معلومات الترتيب',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoChip('الحداثة', '35%', Colors.blue),
                    _buildInfoChip('التفاعل', '25%', Colors.green),
                    _buildInfoChip('التنوع', '20%', Colors.purple),
                    _buildInfoChip('عشوائي', '20%', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }
}
