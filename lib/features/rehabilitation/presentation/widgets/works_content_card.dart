import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../screens/center_content_model.dart';

class WorksContentCard extends StatelessWidget {
  final CenterContentModel content;
  final VoidCallback? onYouTubeTap;
  final VoidCallback? onVideoTap;

  const WorksContentCard({
    super.key,
    required this.content,
    this.onYouTubeTap,
    this.onVideoTap,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return 'منذ ${diff.inMinutes} دقيقة';
      }
      return 'منذ ${diff.inHours} ساعة';
    } else if (diff.inDays < 30) {
      return 'منذ ${diff.inDays} يوم';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image or Video Thumbnail
          if (content.imageUrl != null &&
              content.type != 'video' &&
              content.type != 'youtube')
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                content.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          // YouTube Video
          if (content.type == 'youtube' && content.videoUrl != null)
            InkWell(
              onTap: onYouTubeTap,
              child: Container(
                height: 200,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      'https://img.youtube.com/vi/${YoutubePlayer.convertUrlToId(content.videoUrl!)}/0.jpg',
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Icon(
                              Icons.video_library,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Uploaded Video
          if (content.type == 'video' && content.videoUrl != null)
            InkWell(
              onTap: onVideoTap,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade900, Colors.purple.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Video icon background
                    Icon(
                      Icons.videocam_rounded,
                      size: 80,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    // Play button
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    // Video label
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'اضغط للتشغيل',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      content.type == 'offer'
                          ? Icons.local_offer
                          : content.type == 'video'
                          ? Icons.video_library
                          : Icons.image,
                      color: Colors.purple,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      content.type == 'offer'
                          ? 'عرض خاص'
                          : content.type == 'video' || content.type == 'youtube'
                          ? 'فيديو'
                          : 'معرض الأعمال',
                      style: TextStyle(
                        color: Colors.purple[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  content.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (content.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    content.description!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _formatDate(content.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
