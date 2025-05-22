import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<File?> pickImageWithDialog(BuildContext context, ImagePicker picker) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Pick from gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );

  if (source != null) {
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      return File(picked.path);
    }
  }

  return null;
}
