import 'dart:io';
import 'package:flutter/material.dart';

class ContentFormSection extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController videoUrlController;
  final String selectedType;
  final File? selectedImage;
  final File? selectedVideo;
  final bool isUploading;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onSubmit;
  final ValueChanged<String?> onTypeChanged;

  const ContentFormSection({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.videoUrlController,
    required this.selectedType,
    required this.selectedImage,
    required this.selectedVideo,
    required this.isUploading,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onSubmit,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'نوع المحتوى',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'offer', child: Text('عرض')),
                DropdownMenuItem(value: 'youtube', child: Text('فيديو يوتيوب')),
                DropdownMenuItem(value: 'video', child: Text('فيديو مرفوع')),
                DropdownMenuItem(value: 'image', child: Text('صورة')),
              ],
              onChanged: onTypeChanged,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'العنوان',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'العنوان مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'الوصف (اختياري)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            if (selectedType == 'youtube') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: videoUrlController,
                decoration: const InputDecoration(
                  labelText: 'رابط الفيديو (YouTube)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (selectedType == 'video') ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onPickVideo,
                icon: const Icon(Icons.video_library),
                label: Text(selectedVideo == null
                    ? 'اختر فيديو (حد أقصى 100 ميجا)'
                    : 'تم اختيار الفيديو'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purple,
                ),
              ),
              if (selectedVideo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'حجم الفيديو: ${(selectedVideo!.lengthSync() / 1024 / 1024).toStringAsFixed(1)} ميجا',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
            ],
            if (selectedType == 'image' || selectedType == 'offer') ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onPickImage,
                icon: const Icon(Icons.image),
                label: Text(selectedImage == null
                    ? 'اختر صورة'
                    : 'تم اختيار الصورة'),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isUploading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('إضافة', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
