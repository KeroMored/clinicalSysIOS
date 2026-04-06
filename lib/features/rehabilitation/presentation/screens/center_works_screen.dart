import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_appbar.dart';
import 'center_content_model.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../widgets/widgets.dart';

class CenterWorksScreen extends StatefulWidget {
  final String centerId;
  final String centerName;

  const CenterWorksScreen({
    super.key,
    required this.centerId,
    required this.centerName,
  });

  @override
  State<CenterWorksScreen> createState() => _CenterWorksScreenState();
}

class _CenterWorksScreenState extends State<CenterWorksScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<CenterContentModel> _contents = [];
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

    setState(() {
      _initialLoading = false;
    });
  }

  Future<void> _loadMoreContents() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('rehabilitation_content')
          .where('centerId', isEqualTo: widget.centerId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
        return;
      }

      final newContents = snapshot.docs
          .map(
            (doc) =>
                CenterContentModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();

      setState(() {
        _contents.addAll(newContents);
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المحتوى: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchYouTube(BuildContext context, String url) async {
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('رابط فيديو غير صحيح')));
      return;
    }

    final controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: YoutubePlayerBuilder(
            player: YoutubePlayer(
              controller: controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.red,
            ),
            builder: (context, player) {
              return Column(children: [player, const SizedBox(height: 16)]);
            },
          ),
        ),
      ),
    );

    controller.dispose();
  }

  void _playUploadedVideo(BuildContext context, String videoUrl, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RehabilitationVideoPlayer(videoUrl: videoUrl, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'أعمال ${widget.centerName}',
        gradient: AppTheme.rehabilitationGradient,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          ),
        ),
        child: _initialLoading
            ? Center(
                child: SpinKitPulsingGrid(
                  color: AppTheme.primaryColor,
                  size: 50,
                ),
              )
            : _contents.isEmpty
            ? const WorksEmptyState()
            : RefreshIndicator(
                onRefresh: _loadInitialContents,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _contents.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _contents.length) {
                      return const WorksLoadingIndicator();
                    }

                    final content = _contents[index];
                    return WorksContentCard(
                      content: content,
                      onYouTubeTap:
                          content.type == 'youtube' && content.videoUrl != null
                          ? () => _launchYouTube(context, content.videoUrl!)
                          : null,
                      onVideoTap:
                          content.type == 'video' && content.videoUrl != null
                          ? () => _playUploadedVideo(
                              context,
                              content.videoUrl!,
                              content.title,
                            )
                          : null,
                    );
                  },
                ),
              ),
      ),
    );
  }
}
