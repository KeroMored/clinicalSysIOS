import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/center_content_model.dart';
import 'content_management_card.dart';
import 'package:clinicalsystem/core/widgets/app_loading_indicator.dart';

class ContentListSection extends StatelessWidget {
  final String centerId;
  final Function(String) onDelete;
  final Function(BuildContext, String) onPlayVideo;

  const ContentListSection({
    super.key,
    required this.centerId,
    required this.onDelete,
    required this.onPlayVideo,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rehabilitation_content')
          .where('centerId', isEqualTo: centerId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: AppLoadingIndicator());
        }

        final contents = snapshot.data!.docs
            .map(
              (doc) => CenterContentModel.fromMap(
                doc.data() as Map<String, dynamic>,
              ),
            )
            .toList();

        if (contents.isEmpty) {
          return const Center(child: Text('لا يوجد محتوى بعد'));
        }

        return ListView.builder(
          itemCount: contents.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final content = contents[index];
            return ContentManagementCard(
              content: content,
              onDelete: () => onDelete(content.id),
              onPlayVideo: onPlayVideo,
            );
          },
        );
      },
    );
  }
}
