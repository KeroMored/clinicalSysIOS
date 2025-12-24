import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'center_content_model.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../widgets/widgets.dart';

class CenterContentManagementScreen extends StatefulWidget {
  final String centerId;

  const CenterContentManagementScreen({
    super.key,
    required this.centerId,
  });

  @override
  State<CenterContentManagementScreen> createState() =>
      _CenterContentManagementScreenState();
}

class _CenterContentManagementScreenState
    extends State<CenterContentManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoUrlController = TextEditingController();

  String _selectedType = 'offer';
  File? _selectedImage;
  File? _selectedVideo;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
          'rehabilitation/content/${widget.centerId}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<String?> _uploadVideo(File video) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
          'rehabilitation/content/${widget.centerId}/${DateTime.now().millisecondsSinceEpoch}.mp4');
      await ref.putFile(video);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      final file = File(video.path);
      final fileSize = await file.length();
      
      // Check file size (100MB = 104857600 bytes)
      if (fileSize > 104857600) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حجم الفيديو يجب أن لا يتجاوز 100 ميجابايت'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      setState(() {
        _selectedVideo = file;
      });
    }
  }

  Future<void> _addContent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == 'image' && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار صورة')),
      );
      return;
    }

    if (_selectedType == 'video' && _selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار فيديو')),
      );
      return;
    }

    if (_selectedType == 'youtube' && _videoUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رابط يوتيوب')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl;
      String? videoUrl;
      
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
      }

      if (_selectedVideo != null) {
        videoUrl = await _uploadVideo(_selectedVideo!);
      } else if (_selectedType == 'youtube') {
        videoUrl = _videoUrlController.text.trim();
      }

      final content = CenterContentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        centerId: widget.centerId,
        type: _selectedType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('rehabilitation_content')
          .doc(content.id)
          .set(content.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم إضافة المحتوى بنجاح'),
              backgroundColor: Colors.green),
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
    _videoUrlController.clear();
    setState(() {
      _selectedImage = null;
      _selectedVideo = null;
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

    if (confirm == true && mounted) {
      await _performDeletion(contentId);
    }
  }

  Future<void> _performDeletion(String contentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('rehabilitation_content')
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حذف المحتوى: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleTypeChanged(String? value) async {
    if (value != null) {
      setState(() {
        _selectedType = value;
        _selectedImage = null;
        _selectedVideo = null;
        _videoUrlController.clear();
      });
    }
  }

  void _handlePickImage() => _pickImage();
  void _handlePickVideo() => _pickVideo();
  void _handleSubmit() => _addContent();

  void _showVideoPlayer(BuildContext context, String videoUrl) {
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رابط فيديو غير صحيح')),
      );
      return;
    }

    final controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            YoutubePlayer(
              controller: controller,
              showVideoProgressIndicator: true,
            ),
            TextButton(
              onPressed: () {
                controller.dispose();
                Navigator.pop(context);
              },
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    ).then((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('إدارة المحتوى والعروض',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          ContentFormSection(
            formKey: _formKey,
            titleController: _titleController,
            descriptionController: _descriptionController,
            videoUrlController: _videoUrlController,
            selectedType: _selectedType,
            selectedImage: _selectedImage,
            selectedVideo: _selectedVideo,
            isUploading: _isUploading,
            onPickImage: _handlePickImage,
            onPickVideo: _handlePickVideo,
            onSubmit: _handleSubmit,
            onTypeChanged: _handleTypeChanged,
          ),
          const Divider(),
          Expanded(
            child: ContentListSection(
              centerId: widget.centerId,
              onDelete: _deleteContent,
              onPlayVideo: _showVideoPlayer,
            ),
          ),
        ],
      ),
    );
  }
}
