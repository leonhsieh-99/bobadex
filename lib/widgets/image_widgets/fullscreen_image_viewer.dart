import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/config/constants.dart';

// --- MODE ENUM ---
enum FullscreenImageMode { upload, edit, view }

// --- GALLERY IMAGE MODEL ---
class GalleryImage {
  final String? id; // DB id (nullable for new uploads)
  final String? url; // For network images
  final File? file;  // For local images

  String comment;
  String visibility;

  GalleryImage.network(
    this.url, {
    this.id,
    this.comment = '',
    this.visibility = 'private',
  }) : file = null;

  GalleryImage.file(
    this.file, {
    this.comment = '',
    this.visibility = 'private',
  })  : url = null,
        id = null;
}

// --- MAIN WIDGET ---
class FullscreenImageViewer extends StatefulWidget {
  final List<GalleryImage> images;
  final int initialIndex;
  final FullscreenImageMode mode;
  final bool isCurrentUser; // Whether user can edit their own images

  /// Callback for saving edits. Only used in edit mode.
  /// Called as: onEdit(GalleryImage img, String newComment, String newVisibility)
  final Future<void> Function(GalleryImage img, String comment, String visibility)? onEdit;

  /// Callback for upload mode: returns all images to parent
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
  late List<TextEditingController> _commentControllers;
  late List<String> _visibilityOptions;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
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
    final userState = context.watch<UserState>();
    final themeColor = Constants.getThemeColor(userState.user.themeSlug);
    final img = widget.images[currentIndex];
    final isEditing = editingIndex == currentIndex;
    final uploadMode = widget.mode == FullscreenImageMode.upload;
    final editMode = widget.mode == FullscreenImageMode.edit;
    final canEdit = widget.isCurrentUser && (editMode || uploadMode);

    return Scaffold(
      backgroundColor: themeColor.shade50,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // We'll use the full available height!
            return Column(
              children: [
                Flexible(
                  flex: isEditing || uploadMode ? 7 : 9,
                  child: SizedBox(
                    width: double.infinity,
                    child: PhotoViewGallery.builder(
                      backgroundDecoration: BoxDecoration(color: Colors.black),
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
                        return PhotoViewGalleryPageOptions(
                          imageProvider: img.file != null
                            ? FileImage(img.file!)
                            : NetworkImage(img.url!) as ImageProvider,
                          minScale: PhotoViewComputedScale.contained,
                          maxScale: PhotoViewComputedScale.covered * 2,
                          heroAttributes: PhotoViewHeroAttributes(
                            tag: img.url ?? img.file?.path ?? ''),
                        );
                      },
                      loadingBuilder: (context, _) => Center(child: CircularProgressIndicator()),
                    ),
                  ),                
                ),
                SizedBox(
                  height: 30,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Text(
                          '${currentIndex + 1}/${widget.images.length}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (widget.isCurrentUser)
                        Positioned(
                          right: 16,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (widget.isCurrentUser || widget.mode != FullscreenImageMode.upload)
                                ? img.visibility
                                : '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Flexible for bottom controls and comment, wrap in scroll view
                Flexible(
                  flex: isEditing || uploadMode ? 3 : 1,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    child: Builder(
                      builder: (context) {
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
                        // Default view-only mode
                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (img.comment.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Text(img.comment, style: TextStyle(fontSize: 20)),
                                    ),
                                ],
                              ),
                            ),
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
                      },
                    ),
                  ),
                ),
              ],
            );
          },
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
