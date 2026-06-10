import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../delivery/data/models/delivery_model.dart';
import 'delivery_detail_screen.dart';
import 'package:mallawycare/core/widgets/app_loading_indicator.dart';

class DeliveryListScreen extends StatefulWidget {
  const DeliveryListScreen({super.key});

  @override
  State<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends State<DeliveryListScreen> {
  static const Color _brandColor = Color(0xFF0E7787);
  static const Color _brandColorDark = Color(0xFF0B6572);
  static const int _pageSize = 10;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final List<DeliveryModel> _deliveries = [];

  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
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
      if (!_isLoading && _hasMore && _searchQuery.isEmpty) {
        _loadDeliveries();
      }
    }
  }

  Future<void> _loadDeliveries() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('deliveries')
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'approved')
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

      final newDeliveries = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return DeliveryModel.fromMap({'id': doc.id, ...data});
      }).toList();

      if (mounted) {
        setState(() {
          _deliveries.addAll(newDeliveries);
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
            content: Text('خطأ في تحميل الدليفري: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshDeliveries() async {
    setState(() {
      _deliveries.clear();
      _lastDocument = null;
      _hasMore = true;
      _searchQuery = '';
      _searchController.clear();
    });
    await _loadDeliveries();
  }

  Future<void> _searchDeliveries(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      await _refreshDeliveries();
      return;
    }

    setState(() {
      _searchQuery = trimmed;
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('deliveries')
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'approved')
          .get();

      final lower = trimmed.toLowerCase();
      final searchResults = snapshot.docs
          .map((doc) => DeliveryModel.fromMap({'id': doc.id, ...doc.data()}))
          .where(
            (delivery) =>
                delivery.deliveryName.toLowerCase().contains(lower) ||
                delivery.governorate.toLowerCase().contains(lower) ||
                delivery.city.toLowerCase().contains(lower),
          )
          .toList();

      if (mounted) {
        setState(() {
          _deliveries
            ..clear()
            ..addAll(searchResults);
          _hasMore = false;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openDeliveryDetails(DeliveryModel delivery) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryDetailScreen(delivery: delivery),
      ),
    );
  }

  Future<void> _callDelivery(DeliveryModel delivery) async {
    final phone = delivery.primaryPhone.trim();
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يوجد رقم هاتف متاح حالياً')),
        );
      }
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن إجراء المكالمة حالياً')),
      );
    }
  }

  String _deliveryInitial(DeliveryModel delivery) {
    final name = delivery.deliveryName.trim();
    if (name.isEmpty) return 'د';
    return name.characters.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'الدليفري المتاح',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _brandColor,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _searchDeliveries,
                      onChanged: (value) {
                        if (value.trim().isEmpty && _searchQuery.isNotEmpty) {
                          _refreshDeliveries();
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'ابحث عن دليفري  ...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF6B7280),
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _searchDeliveries(_searchController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _brandColor,
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: _brandColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshDeliveries,
              child: _isLoading && _deliveries.isEmpty
                  ? const Center(
                      child: AppLoadingIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_brandColor),
                      ),
                    )
                  : _deliveries.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        const SizedBox(height: 70),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.delivery_dining_rounded,
                                size: 52,
                                color: Color(0xFF9CA3AF),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'لا يوجد دليفري متاح حالياً',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'جرّب تغيير البحث أو تحديث الصفحة',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      itemCount: _deliveries.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _deliveries.length) {
                          return _hasMore
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: AppLoadingIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _brandColor,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }

                        final delivery = _deliveries[index];
                        return _buildDeliveryCard(delivery);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(DeliveryModel delivery) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDeliveryDetails(delivery),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [_brandColor, _brandColorDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _brandColor.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _deliveryInitial(delivery),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery.deliveryName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            delivery.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Color(0xFFB45309),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.favorite_rounded,
                            size: 13,
                            color: Color(0xFFE11D48),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${delivery.likesCount}',
                            style: const TextStyle(
                              color: Color(0xFFBE123C),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 15,
                            color: _brandColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${delivery.center.isEmpty ? delivery.city : delivery.center} - ${delivery.governorate}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF4B5563),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F3F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCFE5EA)),
                  ),
                  child: IconButton(
                    onPressed: () => _callDelivery(delivery),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.call_rounded,
                      size: 18,
                      color: _brandColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
