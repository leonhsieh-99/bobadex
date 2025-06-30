import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class GalleryImage {
  final String? url; // for network images
  final File? file;  // for local images

  GalleryImage.network(this.url) : file = null;
  GalleryImage.file(this.file) : url = null;
}

class FullscreenImageViewer extends StatefulWidget {
  final List<GalleryImage> images;
  final int initialIndex;

  const FullscreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PhotoViewGallery.builder(
            backgroundDecoration: BoxDecoration(color: Colors.black),
            itemCount: widget.images.length,
            pageController: PageController(initialPage: widget.initialIndex),
            onPageChanged: (index) => setState(() => currentIndex = index),
            builder: (context, index) {
              final img = widget.images[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: img.file != null
                  ? FileImage(img.file!)
                  : NetworkImage(img.url!) as ImageProvider,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes: PhotoViewHeroAttributes(tag: img.url ?? img.file!.path),
              );
            },
            loadingBuilder: (context, _) => Center(child: CircularProgressIndicator()),
          ),
          // Page indicator and close button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  // Page indicator
                  Text(
                    '${currentIndex + 1} / ${widget.images.length}',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  // Optional: placeholder for symmetry
                  SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
