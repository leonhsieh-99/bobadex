import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploaderHelper {
  static final _supabase = Supabase.instance.client;

  static Future<String> uploadImage({
    required File file,
    required String folder,
    bool generateThumbnail = false,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$folder/$timestamp.jpg';

    final bytes = await FlutterImageCompress.compressWithFile(
      file.path,
      minWidth: 800,
      quality: 80,
    );

    await _supabase.storage.from('media-uploads').uploadBinary(
      path,
      bytes!,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000'
      ),
    );

    if (generateThumbnail) {
      final thumbBytes = await FlutterImageCompress.compressWithFile(
        file.path,
        minWidth: 300,
        quality: 70,
      );
      await _supabase.storage.from('media-uploads').updateBinary(
        'thumbs/$path',
        thumbBytes!,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=31536000'
        ),
      );
    }
    return path;
  }
  static Future<void> deleteImage(String path) async {
    if (path.isEmpty || path.startsWith('/')) return;

    await _supabase.storage.from('media-uploads').remove([
      path,
      'thumbs/$path',
    ]);
  }
}