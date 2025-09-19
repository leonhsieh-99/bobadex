import 'dart:io';
import 'package:bobadex/config/constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ImageUploaderHelper {
  static final _supabase = Supabase.instance.client;
  static const List<String> _supportedExtensions = [
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif'
  ];

  static Future<String> uploadImage({
    required File file,
    required String folder,
  }) async {
    if (!await file.exists()) {
      throw Exception('File does not exist');
    }

    final extension = file.path.split('.').last.toLowerCase();
    if (!_supportedExtensions.contains(extension)) {
      throw Exception(
        'Unsupported file format. Please use: ${_supportedExtensions.join(', ')}',
      );
    }

    final uuid = const Uuid().v4();
    final path = '$folder/$uuid.jpg';

    final isGif = extension == 'gif';
    List<int>? fileBytes;

    if (isGif) {
      fileBytes = await file.readAsBytes();
    } else {
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

    if (fileBytes.length > Constants.maxFileSize) {
      throw Exception('File size exceeds maximum limit of 10MB after compression.');
    }

    await _supabase.storage.from('media-uploads').uploadBinary(
      path,
      Uint8List.fromList(fileBytes),
      fileOptions: FileOptions(
        contentType: isGif ? 'image/gif' : 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      ),
    );

    return path;
  }

  static Future<void> deleteImage(String path) async {
    if (path.isEmpty || path.startsWith('/')) return;
    try {
      await _supabase.storage.from('media-uploads').remove([path]);
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }
}
