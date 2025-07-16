import 'dart:io';

import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

// MODE ENUM
enum FullscreenImageMode { upload, edit, view }

// --- GALLERY IMAGE MODEL (add user fields) ---
class GalleryImage {
  final String? id; // DB id (nullable for new uploads)
  final String? url; // For network images
  final String? thumbUrl; // palceholder
  final File? file;
  String comment;
  String visibility;
  String? userThumbUrl;
  String? userName;

  GalleryImage({
    this.url,
    this. thumbUrl,
    this.id,
    this.file,
    this.comment = '',
    this.visibility = 'private',
    this.userThumbUrl,
    this.userName,
  });
}

// --- MAIN WIDGET ---
class FullscreenImageViewer extends StatefulWidget {
  final List<GalleryImage> images;
  final int initialIndex;
  final FullscreenImageMode mode;
  final bool isCurrentUser;
  final Future<void> Function(GalleryImage img, String comment, String visibility)? onEdit;
  final void Function(List<GalleryImage> images)? onUpload;

  const FullscreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.mode = FullscreenImageMode.view,
    this.isCurrentUser = false,
    this.onEdit,
    this.onUpload,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late int currentIndex;
  int? editingIndex;
  late PageController _pageController;
  late ExtendedPageController _extendedPageController;
  late List<TextEditingController> _commentControllers;
  late List<String> _visibilityOptions;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
    _extendedPageController = ExtendedPageController(initialPage: currentIndex);
    _commentControllers = widget.images
        .map((img) => TextEditingController(text: img.comment))
        .toList();
    _visibilityOptions = widget.images
        .map((img) => img.visibility)
        .toList();
  }

  void _startEdit(int index) {
    setState(() => editingIndex = index);
  }

  void _cancelEdit() {
    setState(() => editingIndex = null);
  }

  Future<void> _saveEdit(int idx) async {
    final img = widget.images[idx];
    final newComment = _commentControllers[idx].text.trim();
    final newVisibility = _visibilityOptions[idx];
    if (widget.onEdit != null && img.id != null) {
      await widget.onEdit!(img, newComment, newVisibility);
      setState(() {
        img.comment = newComment;
        img.visibility = newVisibility;
        editingIndex = null;
      });
    }
  }

  void _submitUploads() {
    for (int i = 0; i < widget.images.length; i++) {
      widget.images[i].comment = _commentControllers[i].text.trim();
      widget.images[i].visibility = _visibilityOptions[i];
    }
    widget.onUpload?.call(widget.images);
    Navigator.pop(context, widget.images);
  }

  @override
  Widget build(BuildContext context) {
    final img = widget.images[currentIndex];
    final isEditing = editingIndex == currentIndex;
    final uploadMode = widget.mode == FullscreenImageMode.upload;
    final editMode = widget.mode == FullscreenImageMode.edit;
    final canEdit = widget.isCurrentUser && (editMode || uploadMode);

    final infoEditArea = Container(
      width: double.infinity,
      color: Colors.white.withOpacity(0.97),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Builder(builder: (context) {
        // --- UPLOAD/EDIT MODES ---
        if (uploadMode) {
          return _UploadOrEditFields(
            commentController: _commentControllers[currentIndex],
            visibility: _visibilityOptions[currentIndex],
            onVisibilityChanged: (v) =>
                setState(() => _visibilityOptions[currentIndex] = v),
            onPrev: currentIndex > 0
                ? () => _pageController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  )
                : null,
            onNext: currentIndex < widget.images.length - 1
                ? () => _pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  )
                : null,
            onUpload: _submitUploads,
          );
        }
        if (editMode && isEditing) {
          return _UploadOrEditFields(
            commentController: _commentControllers[currentIndex],
            visibility: _visibilityOptions[currentIndex],
            onVisibilityChanged: (v) =>
                setState(() => _visibilityOptions[currentIndex] = v),
            onSave: () => _saveEdit(currentIndex),
            onCancel: _cancelEdit,
          );
        }
        // --- VIEW MODE ---
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + name
            Column(
              children: [
                Row(
                  children: [
                    if (img.userThumbUrl != null && img.userThumbUrl!.isNotEmpty) ThumbPic(url: img.userThumbUrl, size: 40),
                    SizedBox(width: 12),
                    Text(
                      img.userName ?? '',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ],
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(top: 6.0, bottom: 2.0),
                  child: Text(
                    img.comment,
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey[800]),
                  ),
                ),
              ],
            ),
            // Action buttons
            Spacer(),
            if (canEdit && widget.mode == FullscreenImageMode.edit)
              IconButton(
                icon: Icon(Icons.edit, color: Colors.grey[800]),
                onPressed: () => _startEdit(currentIndex),
              ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.grey[700]),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      }),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // IMAGE GALLERY
            Expanded(
              child: uploadMode
                ? PhotoViewGallery.builder(
                    backgroundDecoration: BoxDecoration(color: Colors.grey[50]),
                    itemCount: widget.images.length,
                    pageController: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        currentIndex = index;
                        editingIndex = null;
                      });
                    },
                    builder: (context, index) {
                      final img = widget.images[index];
                      return PhotoViewGalleryPageOptions.customChild(
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 2,
                        child: Image.file(img.file!)
                      );
                    },
                    loadingBuilder: (context, _) => Center(child: CircularProgressIndicator()),
                  )
                : ExtendedImageSlidePage(
                  child: ExtendedImageGesturePageView.builder(
                    itemCount: widget.images.length,
                    controller: _extendedPageController,
                    itemBuilder: (context, index) {
                      final img = widget.images[index];
                      return Hero(
                        tag: img.id!,
                        child: ExtendedImage.network(
                          img.url!,
                          fit: BoxFit.contain,
                          mode: ExtendedImageMode.gesture,
                          initGestureConfigHandler: (state) => GestureConfig(
                            inPageView: true,
                            initialScale: 1.0,
                            cacheGesture: true,
                          ),
                          loadStateChanged: (state) {
                            if (state.extendedImageLoadState == LoadState.loading) {
                              return Image.network(img.thumbUrl!, fit: BoxFit.contain);
                            }
                            return null;
                          },
                          enableSlideOutPage: true,
                        )
                      ); 
                    },
                    onPageChanged: (int index) {
                      setState(() => currentIndex = index);
                    },
                  )
                )
            ),
            infoEditArea,
          ],
        ),
      ),
    );
  }
}

// Helper widget for upload/edit fields
class _UploadOrEditFields extends StatelessWidget {
  final TextEditingController commentController;
  final String visibility;
  final ValueChanged<String>? onVisibilityChanged;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onUpload;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;

  const _UploadOrEditFields({
    required this.commentController,
    required this.visibility,
    this.onVisibilityChanged,
    this.onPrev,
    this.onNext,
    this.onUpload,
    this.onSave,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: commentController,
          decoration: InputDecoration(
            labelText: 'Comment (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 1,
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: visibility,
          items: ['private', 'public']
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: onVisibilityChanged == null
              ? null
              : (v) {
                  if (v != null) onVisibilityChanged!(v);
                },
          decoration: InputDecoration(
            labelText: 'Visibility',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        if (onPrev != null || onNext != null || onUpload != null || onSave != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (onPrev != null)
                TextButton(
                  onPressed: onPrev,
                  child: Text('Prev'),
                ),
              if (onUpload != null)
                ElevatedButton.icon(
                  onPressed: onUpload,
                  icon: Icon(Icons.cloud_upload),
                  label: Text('Upload All'),
                ),
              if (onSave != null)
                ElevatedButton.icon(
                  onPressed: onSave,
                  icon: Icon(Icons.save),
                  label: Text('Save'),
                ),
              if (onCancel != null)
                OutlinedButton(
                  onPressed: onCancel,
                  child: Text('Cancel'),
                ),
              if (onNext != null)
                TextButton(
                  onPressed: onNext,
                  child: Text('Next'),
                ),
            ],
          ),
      ],
    );
  }
}
