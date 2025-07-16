import 'dart:io';
import 'package:bobadex/widgets/image_widgets/fullscreen_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MultiselectImagePickerDialog extends StatefulWidget {

  const MultiselectImagePickerDialog({
    super.key,
  });

  @override
  State<MultiselectImagePickerDialog> createState() => _MultiselectImagePickerDialogState();
}

class _MultiselectImagePickerDialogState extends State<MultiselectImagePickerDialog> {
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    setState(() {
      _selectedImages.clear();
      _selectedImages.addAll(picked.map((x) => File(x.path)));
    });
  }

  void _startDetailsFlow() async {
    final images = _selectedImages.map((file) => GalleryImage(file: file)).toList();
    final result = await Navigator.of(context).push<List<GalleryImage>>(
      MaterialPageRoute(builder: (_) => FullscreenImageViewer(
        images: images,
        mode: FullscreenImageMode.upload,
      )),
    );
    if (result != null && result.isNotEmpty) {
      if (mounted)Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Photos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.photo_library),
              label: Text('Pick Photos'),
              onPressed: _pickImages,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                separatorBuilder: (_, __) => SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final img = _selectedImages[idx];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(img, width: 70, height: 70, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 0, right: 0,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImages.removeAt(idx)),
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedImages.isNotEmpty
                      ? _startDetailsFlow
                      : null,
                  child: Text('Next'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
