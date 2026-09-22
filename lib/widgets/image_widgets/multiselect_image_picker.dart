import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bobadex/widgets/image_widgets/fullscreen_image_viewer.dart';
import 'package:bobadex/ui/theme/boba_context.dart';

class MultiselectImagePicker extends StatefulWidget {
  final int maxImages;
  final Function(List<GalleryImage>)? onImagesSelected;

  const MultiselectImagePicker({
    super.key,
    this.maxImages = 10,
    this.onImagesSelected,
  });

  @override
  State<MultiselectImagePicker> createState() => _MultiselectImagePicker();
}

class _MultiselectImagePicker extends State<MultiselectImagePicker> {
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _showImageSourceBottomSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ImageSourceBottomSheet(
        onCameraSelected: () => _pickFromCamera(),
        onGallerySelected: () => _pickFromGallery(),
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    Navigator.of(context).pop(); // Close bottom sheet

    setState(() => _isLoading = true);

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        final File imageFile = File(image.path);
        setState(() {
          _selectedImages.add(imageFile);
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to capture image: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    Navigator.of(context).pop(); // Close bottom sheet

    setState(() => _isLoading = true);

    try {
      // For multiple selection, we'll pick one at a time for now
      // This ensures deterministic behavior without complex gallery management
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty && mounted) {
        final List<File> newFiles = images
            .map((xFile) => File(xFile.path))
            .toList();

        // Check if adding these would exceed max limit
        if (_selectedImages.length + newFiles.length > widget.maxImages) {
          final allowedCount = widget.maxImages - _selectedImages.length;
          _showErrorSnackBar('Only $allowedCount more images allowed');
          setState(() {
            _selectedImages.addAll(newFiles.take(allowedCount));
          });
        } else {
          setState(() {
            _selectedImages.addAll(newFiles);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to select images: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.boba.danger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _startDetailsFlow() async {
    final images = _selectedImages
        .map((file) => GalleryImage(file: file))
        .toList();
    final result = await Navigator.of(context).push<List<GalleryImage>>(
      MaterialPageRoute(
        builder: (_) => FullscreenImageViewer(
          images: images,
          mode: FullscreenImageMode.upload,
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      widget.onImagesSelected?.call(result);
      if (mounted) Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.boba.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  color: context.boba.inkMuted,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Select Photos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: context.boba.ink,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: context.boba.inkMuted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Add photo button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _showImageSourceBottomSheet,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: Text(_isLoading ? 'Loading...' : 'Add Photos'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: context.boba.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Selected images preview
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final image = _selectedImages[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            image,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: context.boba.surfaceAlt,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.error_outline),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: context.boba.danger,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: context.boba.onImage,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: context.boba.accentInk,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectedImages.isNotEmpty && !_isLoading
                      ? _startDetailsFlow
                      : null,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: context.boba.onAccent,
                    disabledBackgroundColor: context.boba.surfaceAlt,
                    disabledForegroundColor: context.boba.inkFaint,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageSourceBottomSheet extends StatelessWidget {
  final VoidCallback onCameraSelected;
  final VoidCallback onGallerySelected;
  final VoidCallback onCancel;

  const _ImageSourceBottomSheet({
    required this.onCameraSelected,
    required this.onGallerySelected,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.boba.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.boba.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.boba.ink,
                ),
              ),

              const SizedBox(height: 24),

              // Camera option
              _SourceOption(
                icon: Icons.camera_alt_outlined,
                title: 'Camera',
                subtitle: 'Take a new photo',
                onTap: onCameraSelected,
              ),

              const SizedBox(height: 16),

              // Gallery option
              _SourceOption(
                icon: Icons.photo_library_outlined,
                title: 'Photo Library',
                subtitle: 'Choose from existing photos',
                onTap: onGallerySelected,
              ),

              const SizedBox(height: 24),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.boba.inkMuted,
                    side: BorderSide(color: context.boba.outline),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: context.boba.outline,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.boba.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: context.boba.inkMuted,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.boba.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.boba.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: context.boba.inkFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
