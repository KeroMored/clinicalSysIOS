import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../../core/theme/app_theme.dart';
import 'package:mallawycare/core/widgets/app_loading_indicator.dart';

class GymContentModel {
  final String id;
  final String gymId;
  final String type; // 'offer', 'image'
  final String title;
  final String? description;
  final String? mediaUrl; // Image URL
  final DateTime createdAt;

  GymContentModel({
    required this.id,
    required this.gymId,
    required this.type,
    required this.title,
    this.description,
    this.mediaUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gymId': gymId,
      'type': type,
      'title': title,
      'description': description,
      'mediaUrl': mediaUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory GymContentModel.fromMap(Map<String, dynamic> map) {
    return GymContentModel(
      id: map['id'] ?? '',
      gymId: map['gymId'] ?? '',
      type: map['type'] ?? 'offer',
      title: map['title'] ?? '',
      description: map['description'],
      mediaUrl: map['mediaUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

class GymContentManagementScreen extends StatefulWidget {
  final String gymId;

  const GymContentManagementScreen({super.key, required this.gymId});

  @override
  State<GymContentManagementScreen> createState() =>
      _GymContentManagementScreenState();
}

class _GymContentManagementScreenState
    extends State<GymContentManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'offer';
  File? _selectedMedia;
  bool _isUploading = false;

  Future<void> _sendContentNotification({
    required String title,
    String? description,
    required String type,
  }) async {
    try {
      final gymDoc = await FirebaseFirestore.instance
          .collection('gyms')
          .doc(widget.gymId)
          .get();

      if (!gymDoc.exists) return;

      final gymName = (gymDoc.data()?['name'] ?? 'جيم جديد').toString();

      final notificationTitle = type == 'offer'
          ? 'عرض جديد من $gymName'
          : 'محتوى جديد من $gymName';

      final notificationMessage =
          description != null && description.trim().isNotEmpty
          ? '$title\n$description'
          : title;

      await FirebaseFirestore.instance.collection('gym_notifications').add({
        'gymId': widget.gymId,
        'gymName': gymName,
        'title': notificationTitle,
        'message': notificationMessage,
        'contentType': type,
        'createdAt': FieldValue.serverTimestamp(),
        'topic': 'all_users',
        'sent': false,
      });
    } catch (e) {
      // Notification failure should not block content publishing.
      debugPrint('Failed to queue gym notification: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final file = File(image.path);
      final fileSize = await file.length();

      // Check file size (100MB = 104857600 bytes)
      if (fileSize > 104857600) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حجم الصورة يجب أن لا يتجاوز 100 ميجابايت'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedMedia = file;
      });
    }
  }

  Future<String?> _uploadMedia(File media, String type) async {
    try {
      final extension = 'jpg';
      final ref = FirebaseStorage.instance.ref().child(
        'gyms/${widget.gymId}/content/${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      await ref.putFile(media);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _addContent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == 'image' && _selectedMedia == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار صورة')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? mediaUrl;
      if (_selectedMedia != null) {
        mediaUrl = await _uploadMedia(_selectedMedia!, _selectedType);
      }

      final content = GymContentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        gymId: widget.gymId,
        type: _selectedType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        mediaUrl: mediaUrl,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('gym_content')
          .doc(content.id)
          .set(content.toMap());

      await _sendContentNotification(
        title: content.title,
        description: content.description,
        type: content.type,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة المحتوى بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedMedia = null;
    });
  }

  Future<void> _deleteContent(String contentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذا المحتوى؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('gym_content')
          .doc(contentId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف المحتوى بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'المحتوى والعروض',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Content Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إضافة محتوى جديد',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Type Selection
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'نوع المحتوى',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'offer', child: Text('عرض')),
                      DropdownMenuItem(value: 'image', child: Text('عرض+ صورة')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                        _selectedMedia = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'العنوان',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'حقل مطلوب' : null,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'الوصف (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Image Upload
                  if (_selectedType == 'image')
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: const Text('اختيار صورة (حد أقصى 100MB)'),
                        ),
                        if (_selectedMedia != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'تم اختيار: ${_selectedMedia!.path.split('/').last}',
                            ),
                          ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _addContent,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: _isUploading
                          ? const AppLoadingIndicator(color: Colors.white)
                          : const Text(
                              'إضافة المحتوى',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(height: 1, thickness: 2),
            const SizedBox(height: 16),

            // Content List Header
            const Text(
              'المحتوى المضاف',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Content List
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('gym_content')
                  .where('gymId', isEqualTo: widget.gymId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: AppLoadingIndicator(),
                    ),
                  );
                }

                final contents = snapshot.data!.docs
                    .map(
                      (doc) => GymContentModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                      ),
                    )
                    .toList();

                if (contents.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('لا يوجد محتوى حتى الآن'),
                    ),
                  );
                }

                return Column(
                  children: contents.map((content) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          content.type == 'offer'
                              ? Icons.local_offer
                              : content.type == 'image'
                              ? Icons.image
                              : Icons.image,
                          color: AppTheme.primaryColor,
                        ),
                        title: Text(content.title),
                        subtitle: Text(
                          content.description ?? 'لا يوجد وصف',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteContent(content.id),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
