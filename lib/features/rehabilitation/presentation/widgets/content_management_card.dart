import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../screens/center_content_model.dart';

class ContentManagementCard extends StatelessWidget {
  final CenterContentModel content;
  final VoidCallback onDelete;
  final Function(BuildContext, String) onPlayVideo;

  const ContentManagementCard({
    super.key,
    required this.content,
    required this.onDelete,
    required this.onPlayVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content Preview
          if (content.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                content.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 200,
                  child: Center(child: Icon(Icons.broken_image, size: 50)),
                ),
              ),
            ),
          if (content.videoUrl != null && content.videoUrl!.contains('youtube'))
            Container(
              height: 200,
              color: Colors.black,
              child: Center(
                child: GestureDetector(
                  onTap: () => onPlayVideo(context, content.videoUrl!),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(
                        'https://img.youtube.com/vi/${YoutubePlayer.convertUrlToId(content.videoUrl!)}/0.jpg',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.video_library,
                              size: 80,
                              color: Colors.white,
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
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ListTile(
            leading: Icon(
              content.type == 'video'
                  ? Icons.video_library
                  : content.type == 'image'
                  ? Icons.image
                  : Icons.local_offer,
              color: Colors.purple,
            ),
            title: Text(
              content.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.type == 'offer'
                      ? 'عرض'
                      : content.type == 'video'
                      ? 'فيديو'
                      : 'صورة',
                ),
                if (content.description != null)
                  Text(
                    content.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}
