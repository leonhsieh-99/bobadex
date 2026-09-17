import 'dart:io';
import 'package:bobadex/pages/account_view_page.dart';
import 'package:bobadex/widgets/compact_text_row.dart';
import 'package:bobadex/widgets/report_widget.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum FullscreenImageMode { upload, edit, view }

class GalleryImage {
  final String? id;
  final String? url;
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
  late ExtendedPageController _pageController;
  late List<TextEditingController> _commentControllers;
  late List<String> _visibilityOptions;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = ExtendedPageController(initialPage: currentIndex);
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
  void dispose() {
    _pageController.dispose();
    for (final c in _commentControllers) {
      c.dispose();
    }
    super.dispose();
  }

  GestureConfig _gestureConfig({double maxScale = 1.5}) => GestureConfig(
        inPageView: true,
        initialScale: 1.0,
        minScale: 1.0,
        maxScale: maxScale,
        animationMinScale: 1.0,
        cacheGesture: true,
        speed: 0.85,
        inertialSpeed: 70.0,
      );

  void _onPageChanged(int index) {
    setState(() {
      currentIndex = index;
      editingIndex = null;
    });
  }

  Widget _gallery({required bool uploadMode}) {
    if (uploadMode) {
      return ExtendedImageGesturePageView.builder(
        itemCount: widget.images.length,
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final img = widget.images[index];
          return ExtendedImage.file(
            img.file!,
            fit: BoxFit.contain,
            mode: ExtendedImageMode.gesture,
            initGestureConfigHandler: (_) => _gestureConfig(maxScale: 2.0),
          );
        },
      );
    }

    return ExtendedImageSlidePage(
      slideAxis: SlideAxis.vertical,
      slidePageBackgroundHandler: (offset, pageSize) => Colors.black,
      child: ExtendedImageGesturePageView.builder(
        itemCount: widget.images.length,
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final img = widget.images[index];
          final image = ExtendedImage.network(
            img.url!,
            fit: BoxFit.contain,
            mode: ExtendedImageMode.gesture,
            initGestureConfigHandler: (_) => _gestureConfig(),
            enableSlideOutPage: true,
            loadStateChanged: (state) {
              if (state.extendedImageLoadState == LoadState.loading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                );
              }
              return null;
            },
          );
          if (img.id == null) return image;
          return Hero(tag: img.id!, child: image);
        },
      ),
    );
  }

  Widget _pageDots({Color? color}) {
    if (widget.images.length < 2) return const SizedBox.shrink();
    final activeColor = color ?? Colors.white;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.images.length, (i) {
        final active = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: activeColor.withValues(alpha: active ? 0.95 : 0.35),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }

  Widget _viewCaption(GalleryImage img, {required bool canEdit, required bool editMode}) {
    final comment = img.comment.trim();
    final showUser = widget.showUserInfo && !canEdit;
    final hasCaption = comment.isNotEmpty;
    if (!showUser && !hasCaption && !canEdit && widget.images.length < 2) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.72),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _pageDots(),
              if (showUser) ...[
                if (widget.images.length > 1) const SizedBox(height: 12),
                Row(
                  children: [
                    ThumbPic(
                      path: img.userImagePath ?? '',
                      size: 32,
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        img.userName ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (hasCaption) ...[
                SizedBox(height: showUser ? 8 : (widget.images.length > 1 ? 12 : 0)),
                Text(
                  comment,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (canEdit && editMode)
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          img.visibility,
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () => _startEdit(currentIndex),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final img = widget.images[currentIndex];
    final isEditing = editingIndex == currentIndex;
    final uploadMode = widget.mode == FullscreenImageMode.upload;
    final editMode = widget.mode == FullscreenImageMode.edit;
    final canEdit = widget.isCurrentUser && (editMode || uploadMode);
    final showForm = uploadMode || (editMode && isEditing);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Positioned.fill(child: _gallery(uploadMode: uploadMode)),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      _ChromeIconButton(
                        icon: Icons.close,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      if (!uploadMode && (img.id?.isNotEmpty ?? false))
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz, color: Colors.white),
                          onSelected: (value) {
                            if (value == 'report') {
                              showDialog(
                                context: context,
                                builder: (_) => ReportDialog(
                                  contentType: 'photo',
                                  contentId: img.id ?? '',
                                  reportedUserId: img.userId,
                                ),
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'report',
                              child: Text('Report'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (showForm)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          _pageDots(color: Colors.black87),
                          if (widget.images.length > 1) const SizedBox(height: 12),
                          _UploadOrEditFields(
                            commentController: _commentControllers[currentIndex],
                            visibility: _visibilityOptions[currentIndex],
                            onVisibilityChanged: (v) =>
                                setState(() => _visibilityOptions[currentIndex] = v),
                            onPrev: uploadMode && currentIndex > 0
                                ? () => _pageController.previousPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    )
                                : null,
                            onNext: uploadMode && currentIndex < widget.images.length - 1
                                ? () => _pageController.nextPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    )
                                : null,
                            onUpload: uploadMode ? _submitUploads : null,
                            onSave: editMode ? () => _saveEdit(currentIndex) : null,
                            onCancel: editMode ? _cancelEdit : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _viewCaption(img, canEdit: canEdit, editMode: editMode),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChromeIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ChromeIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

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
        const SizedBox(height: 10),
        if (onPrev != null || onNext != null || onUpload != null || onSave != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (onPrev != null)
                TextButton(
                  onPressed: onPrev,
                  child: const Text('Prev'),
                )
              else
                const SizedBox(width: 64),
              if (onUpload != null)
                ElevatedButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Upload All'),
                ),
              if (onSave != null)
                ElevatedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              if (onCancel != null)
                OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              if (onNext != null)
                TextButton(
                  onPressed: onNext,
                  child: const Text('Next'),
                )
              else if (onPrev != null)
                const SizedBox(width: 64),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: const Icon(
        Icons.sync_alt,
        size: 20,
      ),
      label: Text(isPublic ? 'Public' : 'Private'),
      onPressed: () => onChanged(isPublic ? 'private' : 'public'),
    );
  }
}
