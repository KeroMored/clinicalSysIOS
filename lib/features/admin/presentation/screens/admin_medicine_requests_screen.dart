import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../medicine_requests/data/models/medicine_request_model.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class AdminMedicineRequestsScreen extends StatefulWidget {
  const AdminMedicineRequestsScreen({super.key});

  @override
  State<AdminMedicineRequestsScreen> createState() =>
      _AdminMedicineRequestsScreenState();
}

class _AdminMedicineRequestsScreenState
    extends State<AdminMedicineRequestsScreen> {
  static const Color _primary = Color(0xFF0B8293);
  static const Color _primaryDark = Color(0xFF0A6F7C);

  final ScrollController _scrollController = ScrollController();
  final List<MedicineRequestModel> _requests = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (!_isLoading && _hasMore) {
        _loadRequests();
      }
    }
  }

  Future<void> _loadRequests() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('medicine_requests')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _hasMore = false;
            _isLoading = false;
          });
        }
        return;
      }

      final newRequests = snapshot.docs.map((doc) {
        final requestData = doc.data() as Map<String, dynamic>;
        return MedicineRequestModel.fromJson({'id': doc.id, ...requestData});
      }).toList();

      if (mounted) {
        setState(() {
          _requests.addAll(newRequests);
          _lastDocument = snapshot.docs.last;
          _hasMore = snapshot.docs.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الطلبات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshRequests() async {
    setState(() {
      _requests.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    await _loadRequests();
  }

  void _showImageFullScreen(
    BuildContext context,
    String imageUrl,
    String heroTag,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: Hero(
              tag: heroTag,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text(
                        'فشل تحميل الصورة',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatWhatsAppNumber(String input) {
    String n = input.trim();
    if (n.startsWith('+')) n = n.substring(1);
    if (n.startsWith('20')) return '20$n';
    return '20$n';
  }

  Future<void> _openWhatsApp(
    BuildContext context,
    String phoneNumber,
    String medicineName,
    int quantity,
  ) async {
    final formatted = _formatWhatsAppNumber(phoneNumber);
    if (formatted.isEmpty) {
      return;
    }

    final message =
        '''مرحباً 👋

الدواء [ $medicineName ] متاح لدينا 💊

📦 الكمية المطلوبة: $quantity علبة

يمكنك زيارتنا أو التواصل معنا لطلب الدواء.''';

    final String whatsappUrl =
        "https://wa.me/$formatted?text=${Uri.encodeComponent(message)}";
    try {
      bool launched = await launchUrl(Uri.parse(whatsappUrl));
      if (!launched) {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن فتح واتساب'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  // حذف الطلب (Admin)
  Future<void> _deleteRequest(BuildContext context, String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('medicine_requests')
          .doc(requestId)
          .update({
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
          });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الطلب بنجاح ✓'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // إزالة الطلب من القائمة
      setState(() {
        _requests.removeWhere((req) => req.id == requestId);
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // عمل Block للمستخدم (Admin)
  Future<void> _blockUser(
    BuildContext context,
    String userId,
    String userName,
  ) async {
    try {
      // تحديث حالة المستخدم في Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isDisabled': true,
        'disabledAt': FieldValue.serverTimestamp(),
        'disabledBy': 'admin',
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حظر المستخدم "$userName" بنجاح'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في حظر المستخدم: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context, String requestId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الطلب'),
        content: const Text('هل أنت متأكد من حذف هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteRequest(context, requestId);
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
          'هل أنت متأكد من حظر المستخدم "$userName"?\n\nسيتم تعطيل حسابه ولن يتمكن من تسجيل الدخول.',
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
        onRefresh: _refreshRequests,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Modern SliverAppBar
            SliverAppBar(
              leading: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              expandedHeight: 128,
              floating: false,
              pinned: true,
              backgroundColor: _primary,
              foregroundColor: _primary,
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
                      ],
                    ),
                  ),
                ),
                title: const Text(
                  'طلبات الأدوية (إدارة)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                centerTitle: true,
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(14),
              sliver: _isLoading && _requests.isEmpty
                  ? SliverFillRemaining(
                      child: const Center(
                        child: AppLoadingIndicator(color: _primary),
                      ),
                    )
                  : _requests.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 28),
                              const Text(
                                'لا توجد طلبات حالياً',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'سيظهر هنا طلبات المستخدمين للأدوية',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index == _requests.length) {
                          return _hasMore
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: AppLoadingIndicator(color: _primary),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }

                        final request = _requests[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildRequestCard(context, request),
                        );
                      }, childCount: _requests.length + (_hasMore ? 1 : 0)),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, MedicineRequestModel request) {
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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primary, _primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'طلب ${request.allMedicines.length} ${request.allMedicines.length == 1 ? "دواء" : "أدوية"}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Medicines list
            ...request.allMedicines.asMap().entries.map((entry) {
              final idx = entry.key;
              final med = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primary, _primaryDark],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (med.imageUrl != null && med.imageUrl!.isNotEmpty) ...[
                      Hero(
                        tag: 'medicine_${request.id}_$idx',
                        child: GestureDetector(
                          onTap: () => _showImageFullScreen(
                            context,
                            med.imageUrl!,
                            'medicine_${request.id}_$idx',
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              med.imageUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (med.imageUrl == null || med.imageUrl!.isEmpty)
                            Text(
                              med.medicineName.isNotEmpty
                                  ? med.medicineName
                                  : 'صورة الدواء',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (med.medicineType != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    med.medicineType!,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: _primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${med.quantity} ${med.quantityUnit ?? "علبة"}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 10),

            // User & date info
            Column(
              children: [
                _buildCompactInfo(
                  icon: Icons.person_outline,
                  text: request.userName,
                ),
                const SizedBox(height: 4),
                _buildCompactInfo(
                  icon: Icons.phone_outlined,
                  text: request.phoneNumber,
                ),
                const SizedBox(height: 4),
                _buildCompactInfo(
                  icon: Icons.access_time_outlined,
                  text: _formatDate(request.createdAt),
                ),
              ],
            ),

            // Notes
            if (request.notes != null && request.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.note_outlined,
                      size: 14,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        request.notes!,
                        style: const TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 11,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Admin Action Buttons
            Row(
              children: [
                // زرار الاتصال
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(request.phoneNumber),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('اتصال'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // زرار حذف الطلب
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeleteDialog(context, request.id),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('حذف'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // زرار حظر المستخدم
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showBlockDialog(
                      context,
                      request.userId,
                      request.userName,
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
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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

  Widget _buildCompactInfo({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
