import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cloud_functions/cloud_functions.dart'; // Not needed - removed
import 'package:intl/intl.dart';
import '../../../medicine_requests/data/models/medicine_request_model.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

/// 📋 صفحة إدارة شاملة للطلبات والعروض
/// 
/// تشمل:
/// - طلبات الأدوية
/// - عروض الصيدليات
/// - عروض العيادات
/// - عروض الجيمات
/// - عروض المستلزمات الطبية
/// 
/// مع:
/// ✅ Pagination (10 items per page)
/// ✅ Search (اسم، رقم، عنوان)
/// ✅ حظر المستخدمين (Firebase Auth Disable)
/// ✅ حذف الطلبات/العروض
class AdminAllRequestsScreen extends StatefulWidget {
  const AdminAllRequestsScreen({super.key});

  @override
  State<AdminAllRequestsScreen> createState() =>
      _AdminAllRequestsScreenState();
}

class _AdminAllRequestsScreenState extends State<AdminAllRequestsScreen> {
  static const Color _primary = Color(0xFF0B8293);
  static const Color _primaryDark = Color(0xFF0A6F7C);

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  final List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 10;

  // نوع العرض الحالي
  String _selectedType = 'all'; // all, medicine, pharmacy, clinic, gym, medical_supply
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadItems();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (!_isLoading && _hasMore) {
        _loadItems();
      }
    }
  }

  Future<void> _loadItems() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> newItems = [];

      // جلب طلبات الأدوية
      if (_selectedType == 'all' || _selectedType == 'medicine') {
        final medicineItems = await _loadMedicineRequests();
        newItems.addAll(medicineItems);
      }

      // جلب عروض الصيدليات
      if (_selectedType == 'all' || _selectedType == 'pharmacy') {
        final pharmacyItems = await _loadOffers('offers', 'pharmacy');
        newItems.addAll(pharmacyItems);
      }

      // جلب عروض العيادات
      if (_selectedType == 'all' || _selectedType == 'clinic') {
        final clinicItems = await _loadOffers('clinic_offers', 'clinic');
        newItems.addAll(clinicItems);
      }

      // جلب عروض الجيمات
      if (_selectedType == 'all' || _selectedType == 'gym') {
        final gymItems = await _loadOffers('gym_offers', 'gym');
        newItems.addAll(gymItems);
      }

      // جلب عروض المستلزمات الطبية
      if (_selectedType == 'all' || _selectedType == 'medical_supply') {
        final supplyItems = await _loadOffers('medical_supply_offers', 'medical_supply');
        newItems.addAll(supplyItems);
      }

      // فلترة حسب البحث
      if (_searchQuery.isNotEmpty) {
        newItems = newItems.where((item) {
          final searchLower = _searchQuery.toLowerCase();
          
          // البحث في طلبات الأدوية
          if (item['type'] == 'medicine') {
            final medicineName = (item['medicineName'] ?? '').toString().toLowerCase();
            final userName = (item['userName'] ?? '').toString().toLowerCase();
            final phoneNumber = (item['phoneNumber'] ?? '').toString().toLowerCase();
            return medicineName.contains(searchLower) ||
                   userName.contains(searchLower) ||
                   phoneNumber.contains(searchLower);
          }
          
          // البحث في العروض
          final placeName = (item['placeName'] ?? '').toString().toLowerCase();
          final title = (item['title'] ?? '').toString().toLowerCase();
          final phoneNumber = (item['phoneNumber'] ?? '').toString().toLowerCase();
          
          return placeName.contains(searchLower) ||
                 title.contains(searchLower) ||
                 phoneNumber.contains(searchLower);
        }).toList();
      }

      // ترتيب حسب التاريخ (الأحدث أولاً)
      newItems.sort((a, b) {
        final aDate = a['createdAt'] as DateTime?;
        final bDate = b['createdAt'] as DateTime?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

      // تطبيق Pagination
      final startIndex = _items.length;
      final endIndex = startIndex + _pageSize;
      final paginatedItems = newItems.length > startIndex
          ? newItems.sublist(startIndex, endIndex.clamp(0, newItems.length))
          : <Map<String, dynamic>>[];

      if (mounted) {
        setState(() {
          _items.addAll(paginatedItems);
          _hasMore = endIndex < newItems.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadMedicineRequests() async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('medicine_requests')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(50);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final request = MedicineRequestModel.fromJson({'id': doc.id, ...data});
        
        return {
          'id': doc.id,
          'type': 'medicine',
          'userName': request.userName,
          'phoneNumber': request.phoneNumber,
          'userId': request.userId,
          'medicineName': request.allMedicines.isNotEmpty
              ? request.allMedicines.first.medicineName
              : 'صورة الدواء',
          'medicineCount': request.allMedicines.length,
          'notes': request.notes,
          'createdAt': request.createdAt,
          'rawData': request,
        };
      }).toList();
    } catch (e) {
      print('❌ Error loading medicine requests: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadOffers(
    String collection,
    String offerType,
  ) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection(collection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(50);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        return {
          'id': doc.id,
          'type': offerType,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'placeName': data['pharmacyName'] ??
              data['clinicName'] ??
              data['gymName'] ??
              data['supplyName'] ??
              '',
          'placeId': data['pharmacyId'] ??
              data['clinicId'] ??
              data['gymId'] ??
              data['supplyId'] ??
              '',
          'phoneNumber': '', // سنحتاج جلبه من collection المكان
          'images': List<String>.from(data['images'] ?? []),
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'collection': collection,
        };
      }).toList();
    } catch (e) {
      print('❌ Error loading offers from $collection: $e');
      return [];
    }
  }

  Future<void> _refreshItems() async {
    setState(() {
      _items.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    await _loadItems();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _items.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    _loadItems();
  }

  void _onTypeChanged(String? value) {
    if (value == null) return;
    setState(() {
      _selectedType = value;
      _items.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    _loadItems();
  }

  // حذف الطلب/العرض
  Future<void> _deleteItem(BuildContext context, Map<String, dynamic> item) async {
    try {
      if (item['type'] == 'medicine') {
        await FirebaseFirestore.instance
            .collection('medicine_requests')
            .doc(item['id'])
            .update({
              'status': 'completed',
              'completedAt': FieldValue.serverTimestamp(),
            });
      } else {
        await FirebaseFirestore.instance
            .collection(item['collection'])
            .doc(item['id'])
            .update({
              'isActive': false,
              'deletedAt': FieldValue.serverTimestamp(),
            });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الحذف بنجاح ✓'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }

      setState(() {
        _items.removeWhere((i) => i['id'] == item['id']);
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // حظر المستخدم باستخدام Cloud Function
  Future<void> _blockUser(
    BuildContext context,
    String userId,
    String userName,
  ) async {
    // Feature disabled - cloud_functions package not included
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ميزة الحظر غير مفعلة حالياً'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    /* Original code - commented out (requires cloud_functions package)
    try {
      // عرض loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: AppLoadingIndicator()),
      );

      // استدعاء Cloud Function
      final callable = FirebaseFunctions.instance.httpsCallable('blockUser');
      final result = await callable.call({'userId': userId});

      if (context.mounted) {
        Navigator.pop(context); // إغلاق loading
        
        if (result.data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حظر المستخدم "$userName" بنجاح\n'
                  'لن يتمكن من تسجيل الدخول مجدداً'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          throw Exception('فشل الحظر');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // إغلاق loading في حالة الخطأ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في حظر المستخدم: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
    */
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> item) {
    final itemName = item['type'] == 'medicine'
        ? 'طلب الدواء'
        : 'العرض: ${item['title']}';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف $itemName؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteItem(context, item);
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

  void _showBlockDialog(BuildContext context, String userId, String userName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حظر المستخدم'),
        content: Text(
          'هل أنت متأكد من حظر المستخدم "$userName"?\n\n'
          '⚠️ سيتم تعطيل حسابه في Firebase Authentication\n'
          '⚠️ لن يتمكن من تسجيل الدخول مجدداً',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _blockUser(context, userId, userName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حظر'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: RefreshIndicator(
        onRefresh: _refreshItems,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Modern SliverAppBar
            SliverAppBar(
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: _primary,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primary, _primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_items.length} عنصر',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                title: const Text(
                  'إدارة الطلبات والعروض',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                centerTitle: true,
              ),
            ),

            // Search & Filter Section
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    // Search Box
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'ابحث... (اسم، رقم، عنوان)',
                        prefixIcon: const Icon(Icons.search, color: _primary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filter Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedType,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: _primary),
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('🔍 الكل'),
                            ),
                            DropdownMenuItem(
                              value: 'medicine',
                              child: Text('💊 طلبات الأدوية'),
                            ),
                            DropdownMenuItem(
                              value: 'pharmacy',
                              child: Text('💚 عروض الصيدليات'),
                            ),
                            DropdownMenuItem(
                              value: 'clinic',
                              child: Text('🏥 عروض العيادات'),
                            ),
                            DropdownMenuItem(
                              value: 'gym',
                              child: Text('💪 عروض الجيمات'),
                            ),
                            DropdownMenuItem(
                              value: 'medical_supply',
                              child: Text('🏥 عروض المستلزمات'),
                            ),
                          ],
                          onChanged: _onTypeChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              sliver: _isLoading && _items.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(child: AppLoadingIndicator(color: _primary)),
                    )
                  : _items.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'لا توجد نتائج',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == _items.length) {
                            return _hasMore
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: AppLoadingIndicator(color: _primary),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          }

                          final item = _items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildItemCard(context, item),
                          );
                        },
                        childCount: _items.length + (_hasMore ? 1 : 0),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, Map<String, dynamic> item) {
    final type = item['type'] as String;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Type Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getTypeColors(type),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTypeLabel(type),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(item['createdAt']),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Content based on type
            if (type == 'medicine') ...[
              _buildMedicineContent(item),
            ] else ...[
              _buildOfferContent(item),
            ],

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                if (type == 'medicine') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showBlockDialog(
                        context,
                        item['userId'],
                        item['userName'],
                      ),
                      icon: const Icon(Icons.block, size: 16),
                      label: const Text('حظر'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeleteDialog(context, item),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('حذف'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineContent(Map<String, dynamic> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💊 ${item['medicineName']}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text('👤 ${item['userName']}', style: const TextStyle(fontSize: 12)),
        Text('📞 ${item['phoneNumber']}', style: const TextStyle(fontSize: 12)),
        if (item['medicineCount'] > 1)
          Text(
            '📦 ${item['medicineCount']} أدوية',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildOfferContent(Map<String, dynamic> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item['title'],
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          '📍 ${item['placeName']}',
          style: const TextStyle(fontSize: 12),
        ),
        if (item['description'].isNotEmpty)
          Text(
            item['description'],
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  List<Color> _getTypeColors(String type) {
    switch (type) {
      case 'medicine':
        return [const Color(0xFF0B8293), const Color(0xFF0A6F7C)];
      case 'pharmacy':
        return [const Color(0xFF06B6D4), const Color(0xFF0891B2)];
      case 'clinic':
        return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
      case 'gym':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case 'medical_supply':
        return [const Color(0xFFE91E63), const Color(0xFFC2185B)];
      default:
        return [Colors.grey, Colors.grey];
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'medicine':
        return '💊 طلب دواء';
      case 'pharmacy':
        return '💚 صيدلية';
      case 'clinic':
        return '🏥 عيادة';
      case 'gym':
        return '💪 جيم';
      case 'medical_supply':
        return '🏥 مستلزمات';
      default:
        return 'غير معروف';
    }
  }
}
