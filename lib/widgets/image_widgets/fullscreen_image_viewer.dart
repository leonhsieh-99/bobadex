import 'dart:io';
import 'package:bobadex/pages/account_view_page.dart';
import 'package:bobadex/widgets/compact_text_row.dart';
import 'package:bobadex/widgets/report_widget.dart';
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
  final File? file;
  String comment;
  String visibility;
  String? userImagePath;
  String? userName;
  String? userId;

  GalleryImage({
    this.url,
    this.id,
    this.file,
    this.comment = '',
    this.visibility = 'private',
    this.userImagePath,
    this.userName,
    this.userId,
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
  final bool showUserInfo;

  const FullscreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.mode = FullscreenImageMode.view,
    this.isCurrentUser = false,
    this.onEdit,
    this.onUpload,
    this.showUserInfo = true,
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
    final bgColor = Colors.grey[50];

    final infoEditArea = Container(
      width: double.infinity,
      color: bgColor,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16
      ),
      child: SingleChildScrollView(
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
          return canEdit
            ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!canEdit && widget.showUserInfo)
                  ThumbPic(
                    path: img.userImagePath ?? '',
                    size: 40,
                    onTap: img.userId == null
                        ? null // disables tap + ripple in most GestureDetectors
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AccountViewPage(userId: img.userId!),
                              ),
                            );
                          },
                  ),
                if (!canEdit && widget.showUserInfo) SizedBox(width: 12),
                if (!canEdit && widget.showUserInfo)
                  Text(
                    img.userName ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                if (!canEdit && widget.showUserInfo) SizedBox(width: 12),
                Expanded(
                  child: Text(
                    img.comment,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 20, color: Colors.grey[800]),
                  ),
                ),
                if (canEdit && widget.mode == FullscreenImageMode.edit)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(img.visibility, style: TextStyle(fontSize: 12)),
                  ),
                if (canEdit && widget.mode == FullscreenImageMode.edit)
                  SizedBox(width: 4),
                if (canEdit && widget.mode == FullscreenImageMode.edit)
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.grey[800]),
                    onPressed: () => _startEdit(currentIndex),
                  ),
              ],
            )
          : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showUserInfo)
                Row(
                  children: [
                    ThumbPic(
                      path: img.userImagePath ?? '',
                      size: 40,
                      onTap: img.userId == null
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AccountViewPage(userId: img.userId!),
                              ),
                            );
                          },
                    ),
                    SizedBox(width: 12),
                    Text(
                      img.userName ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20
                      ),
                    ),
                  ],
                ),
              if (widget.showUserInfo) SizedBox(height: 4),
              Text(
                img.comment,
                style: TextStyle(fontSize: 20, color: Colors.grey[800]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        }),
      )
    );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(40),
        child: AppBar(
          actions: [
            PopupMenuButton(
              onSelected: (value) {
                switch(value) {
                  case 'report':
                    showDialog(
                      context: context,
                      builder: (_) => ReportDialog(
                        contentType: 'photo',
                        contentId: img.id ?? '',
                        reportedUserId: img.userId,
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'report',
                  child: Text('Report'),
                ),
              ]
            ),
          ]
        )
      ),
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // IMAGE GALLERY
            Expanded(
              child: Stack(
                children: [
                  uploadMode
                  ? PhotoViewGallery.builder(
                      backgroundDecoration: BoxDecoration(color: bgColor),
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
                    slideAxis: SlideAxis.vertical,
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
                              minScale: 1.0,
                              maxScale: 1.5,
                              animationMinScale: 1.0,
                              cacheGesture: true,
                              speed: 0.85,
                              inertialSpeed: 70.0,
                            ),
                            loadStateChanged: (state) {
                              if (state.extendedImageLoadState == LoadState.loading) {
                                return null; // do something later maybe
                              }
                              return null;
                            },
                            enableSlideOutPage: true,
                          )
                        ); 
                      },
                      onPageChanged: (int index) {
                        setState(() => currentIndex = index);
                        _cancelEdit();
                      },
                    )
                  ),
                ]
              )
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.25,
                minHeight: 0,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 18,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: infoEditArea,
              ),
            ),
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
        CompactTextRow(
          textController: commentController,
          leftFlexStart: 5,
          leftFlexEnd: 10,
          rightFlex: 3,
          maxLength: 30,
          maxLines: 1,
          hintText: 'Description',
          child: VisibilityToggleButton(
            value: visibility,
            onChanged: onVisibilityChanged!,
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

class VisibilityToggleButton extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const VisibilityToggleButton({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isPublic = value == 'public';
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: isPublic ? Colors.green[800] : Colors.grey[700],
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: Icon(
        Icons.sync_alt,
        size: 20,
      ),
      label: Text(isPublic ? 'Public' : 'Private'),
      onPressed: () => onChanged(isPublic ? 'private' : 'public'),
    );
  }
}
