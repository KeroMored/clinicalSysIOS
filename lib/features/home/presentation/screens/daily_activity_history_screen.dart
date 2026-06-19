import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/theme/app_theme.dart';
import 'package:mallawicure/core/widgets/app_loading_indicator.dart';

class DailyActivityHistoryScreen extends StatefulWidget {
  final String userId;

  const DailyActivityHistoryScreen({super.key, required this.userId});

  @override
  State<DailyActivityHistoryScreen> createState() =>
      _DailyActivityHistoryScreenState();
}

class _DailyActivityHistoryScreenState
    extends State<DailyActivityHistoryScreen> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];
  QueryDocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;

  Map<String, dynamic>? _bestDay;
  Map<String, dynamic>? _worstDay;

  static const int _pageSize = 10;

  CollectionReference<Map<String, dynamic>> get _collection => FirebaseFirestore
      .instance
      .collection('users')
      .doc(widget.userId)
      .collection('daily_activity');

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _loadAnalytics();
  }

  Future<void> _loadInitial() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final baseQuery = _collection
          .orderBy('dateKey', descending: true)
          .limit(_pageSize);

      // Render quickly from local cache first, then refresh from network.
      final cached = await baseQuery.get(
        const GetOptions(source: Source.cache),
      );
      if (mounted && cached.docs.isNotEmpty) {
        setState(() {
          _docs
            ..clear()
            ..addAll(cached.docs);
          _lastDoc = cached.docs.last;
          _hasMore = cached.docs.length == _pageSize;
        });
      }

      final snapshot = await baseQuery.get();

      if (!mounted) return;
      setState(() {
        _docs
          ..clear()
          ..addAll(snapshot.docs);
        _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == _pageSize;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (_docs.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر تحميل السجل')));
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore || _lastDoc == null) return;

    setState(() => _isLoading = true);
    try {
      final snapshot = await _collection
          .orderBy('dateKey', descending: true)
          .startAfterDocument(_lastDoc!)
          .limit(_pageSize)
          .get();

      if (!mounted) return;
      setState(() {
        _docs.addAll(snapshot.docs);
        _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : _lastDoc;
        _hasMore = snapshot.docs.length == _pageSize;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحميل المزيد من الأيام')),
      );
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final bestQuery = _collection
          .orderBy('meters', descending: true)
          .limit(1);
      final worstQuery = _collection.orderBy('meters').limit(1);

      final cachedResults = await Future.wait([
        bestQuery.get(const GetOptions(source: Source.cache)),
        worstQuery.get(const GetOptions(source: Source.cache)),
      ]);

      if (mounted) {
        final cachedBest = cachedResults[0];
        final cachedWorst = cachedResults[1];
        if (cachedBest.docs.isNotEmpty || cachedWorst.docs.isNotEmpty) {
          setState(() {
            _bestDay = cachedBest.docs.isNotEmpty
                ? cachedBest.docs.first.data()
                : _bestDay;
            _worstDay = cachedWorst.docs.isNotEmpty
                ? cachedWorst.docs.first.data()
                : _worstDay;
          });
        }
      }

      final liveResults = await Future.wait([
        bestQuery.get(),
        worstQuery.get(),
      ]);
      final best = liveResults[0];
      final worst = liveResults[1];

      if (!mounted) return;
      setState(() {
        _bestDay = best.docs.isNotEmpty ? best.docs.first.data() : null;
        _worstDay = worst.docs.isNotEmpty ? worst.docs.first.data() : null;
      });
    } catch (_) {
      // Keep analytics hidden if indexes/data are not ready.
    }
  }

  String _formatDate(String dateKey) {
    try {
      final parsed = DateTime.parse(dateKey);
      return intl.DateFormat('EEEE - yyyy/MM/dd', 'ar').format(parsed);
    } catch (_) {
      return dateKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('سجل النشاط اليومي'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitial,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAnalyticsCard(),
            const SizedBox(height: 14),
            if (_docs.isEmpty && !_isLoading)
              _buildEmpty()
            else ...[
              ..._docs.map(_buildDayTile),
              if (_hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _loadMore,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: AppLoadingIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more_rounded),
                    label: const Text('تحميل 10 أيام أخرى'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تحليلات سريعة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _analysisItem(
                  title: 'أفضل يوم',
                  value: _bestDay == null
                      ? '--'
                      : '${(_bestDay!['meters'] as num?)?.toStringAsFixed(0) ?? '0'} م',
                  subtitle: _bestDay == null
                      ? ''
                      : (_bestDay!['dateKey'] as String? ?? ''),
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _analysisItem(
                  title: 'أضعف يوم',
                  value: _worstDay == null
                      ? '--'
                      : '${(_worstDay!['meters'] as num?)?.toStringAsFixed(0) ?? '0'} م',
                  subtitle: _worstDay == null
                      ? ''
                      : (_worstDay!['dateKey'] as String? ?? ''),
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _analysisItem({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayTile(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final dateKey = data['dateKey'] as String? ?? '--';
    final meters = (data['meters'] as num?)?.toDouble() ?? 0.0;
    final label = data['performanceLabel'] as String? ?? 'بدون تقييم';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_run_rounded,
              color: Color(0xFF0284C7),
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(dateKey),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'المسافة: ${meters.toStringAsFixed(0)} متر',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF0369A1),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: const Text(
        'لا يوجد سجل نشاط سابق حتى الآن',
        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
      ),
    );
  }
}
