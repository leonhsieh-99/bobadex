import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ImageUploaderHelper {
  static final _supabase = Supabase.instance.client;
  static const int _maxFileSize = 10 * 1024 * 1024; // 10 MB
  static const List<String> _supportedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

  static Future<String> uploadImage({
    required File file,
    required String folder,
    bool generateThumbnail = false,
  }) async {
    // Check file exists
    if (!await file.exists()) {
      throw Exception('File does not exist');
    }

    // Check extension before compression
    final extension = file.path.split('.').last.toLowerCase();
    if (!_supportedExtensions.contains(extension)) {
      throw Exception('Unsupported file format. Please use: ${_supportedExtensions.join(', ')}');
    }

    // Always generate a unique file name
    final uuid = const Uuid().v4();
    final path = '$folder/$uuid.jpg';

    // Special handling for GIF (don't compress)
    final isGif = extension == 'gif';
    List<int>? fileBytes;

    if (isGif) {
      fileBytes = await file.readAsBytes();
    } else {
      // Compress and convert to JPEG for everything else
      fileBytes = await FlutterImageCompress.compressWithFile(
        file.path,
        minWidth: 800,
        quality: 80,
        format: CompressFormat.jpeg,
      );
      if (fileBytes == null) {
        throw Exception('Failed to compress image');
      }
    }

    // Final file size check (after compression)
    if (fileBytes.length > _maxFileSize) {
      throw Exception('File size exceeds maximum limit of 10MB after compression.');
    }

    // Upload the main image
    await _supabase.storage.from('media-uploads').uploadBinary(
      path,
      Uint8List.fromList(fileBytes),
      fileOptions: FileOptions(
        contentType: isGif ? 'image/gif' : 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      ),
    );

    // Thumbnail logic (always JPEG, even if original is GIF)
    if (generateThumbnail) {
      final thumbBytes = await FlutterImageCompress.compressWithFile(
        file.path,
        minWidth: 300,
        quality: 70,
        format: CompressFormat.jpeg,
      );
      if (thumbBytes != null) {
        await _supabase.storage.from('media-uploads').uploadBinary(
          'thumbs/$path',
          thumbBytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            cacheControl: 'public, max-age=31536000',
          ),
        );
      }
    }
    return path;
  }

  static Future<void> deleteImage(String path) async {
    if (path.isEmpty || path.startsWith('/')) return;
    try {
      await _supabase.storage.from('media-uploads').remove([
        path,
        'thumbs/$path',
      ]);
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }
}
