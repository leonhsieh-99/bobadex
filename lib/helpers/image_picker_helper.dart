import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum ImageAction { camera, gallery, delete }

Future<File?> pickImageWithDialog(BuildContext context, ImagePicker picker, bool imageExists) async {
  final action = await showModalBottomSheet<ImageAction>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(context, ImageAction.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Pick from gallery'),
            onTap: () => Navigator.pop(context, ImageAction.gallery),
          ),
          if (imageExists)
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete photo'),
              textColor: Colors.red,
              onTap: () => Navigator.pop(context, ImageAction.delete),
            )
        ],
      ),
    ),
  );

  if (action == ImageAction.camera) {
    final picked = await picker.pickImage(source: ImageSource.camera);
    return picked != null ? File(picked.path) : null;
  } else if (action == ImageAction.gallery) {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    return picked != null ? File(picked.path) : null;
  } else if (action == ImageAction.delete) {
    return File('');
  }

  return null;
}
