import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../gym/presentation/pages/gym_content_management_screen.dart';

class GymWorksScreen extends StatefulWidget {
  final String gymId;

  const GymWorksScreen({super.key, required this.gymId});

  @override
  State<GymWorksScreen> createState() => _GymWorksScreenState();
}

class _GymWorksScreenState extends State<GymWorksScreen> {
  static const Color _primaryColor = Color(0xFF0B8293);
  static const Color _titleColor = Color(0xFF0F172A);

  final ScrollController _scrollController = ScrollController();
  final List<GymContentModel> _contents = [];

  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _initialLoading = true;

  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadInitialContents();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreContents();
      }
    }
  }

  Future<void> _loadInitialContents() async {
    setState(() {
      _initialLoading = true;
      _contents.clear();
      _lastDocument = null;
      _hasMore = true;
    });

    await _loadMoreContents();

    if (mounted) {
      setState(() {
        _initialLoading = false;
      });
    }
  }

  Future<void> _loadMoreContents() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('gym_content')
          .where('gymId', isEqualTo: widget.gymId)
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
            _isLoadingMore = false;
          });
        }
        return;
      }

      final newContents = snapshot.docs
          .map(
            (doc) => GymContentModel.fromMap({
              'id': doc.id,
              ...(doc.data() as Map<String, dynamic>),
            }),
          )
          .where(
            (content) => content.type != 'video' && content.type != 'youtube',
          )
          .toList();

      if (mounted) {
        setState(() {
          _contents.addAll(newContents);
          _lastDocument = snapshot.docs.last;
          _hasMore = snapshot.docs.length == _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المحتوى: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'أعمالنا وعروضنا',
          style: TextStyle(
            color: _titleColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _primaryColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: _initialLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SpinKitPulsingGrid(color: _primaryColor, size: 44),
                  SizedBox(height: 14),
                  Text(
                    'جاري تحميل المحتوى...',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          : _contents.isEmpty
          ? const Center(
              child: Text(
                'لا يوجد محتوى متاح حالياً',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadInitialContents,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                itemCount: _contents.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _contents.length) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _isLoadingMore
                            ? const SpinKitPulsingGrid(
                                color: _primaryColor,
                                size: 20,
                              )
                            : const SizedBox.shrink(),
                      ),
                    );
                  }

                  final content = _contents[index];
                  return _buildContentCard(content);
                },
              ),
            ),
    );
  }

  Widget _buildContentCard(GymContentModel content) {
    final isOffer = content.type == 'offer';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (content.mediaUrl != null && content.mediaUrl!.trim().isNotEmpty)
              Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 210,
                    child: Image.network(
                      content.mediaUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFE2E8F0),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _buildTypeBadge(isOffer),
                  ),
                ],
              )
            else
              (isOffer
                  ? _buildLegacyOfferPlaceholder()
                  : Container(
                      width: double.infinity,
                      height: 130,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_rounded,
                          size: 42,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    )),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (content.mediaUrl == null ||
                      content.mediaUrl!.trim().isEmpty)
                    _buildTypeBadge(isOffer),
                  if (content.mediaUrl == null ||
                      content.mediaUrl!.trim().isEmpty)
                    const SizedBox(height: 8),
                  Text(
                    content.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _titleColor,
                    ),
                  ),
                  if (content.description != null &&
                      content.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      content.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(content.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(bool isOffer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOffer ? const Color(0xFFDCFCE7) : const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOffer ? const Color(0xFF86EFAC) : const Color(0xFF7DD3FC),
        ),
      ),
      child: Text(
        isOffer ? 'عرض خاص' : 'صورة',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isOffer ? const Color(0xFF15803D) : const Color(0xFF0369A1),
        ),
      ),
    );
  }

  Widget _buildLegacyOfferPlaceholder() {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(painter: _OfferPatternPainter()),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_offer,
                    size: 60,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Text(
                    'عرض خاص',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B6B),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes <= 0) return 'الآن';
        return 'منذ ${diff.inMinutes} دقيقة';
      }
      return 'منذ ${diff.inHours} ساعة';
    }
    if (diff.inDays < 30) {
      return 'منذ ${diff.inDays} يوم';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _OfferPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (double i = -size.height; i < size.width; i += 30) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
