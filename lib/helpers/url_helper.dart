import 'package:supabase_flutter/supabase_flutter.dart';

String publicUrl(String bucket, String path) =>
    Supabase.instance.client.storage.from(bucket).getPublicUrl(
      path.startsWith('/') ? path.substring(1) : path,
    );

/// e.g. thumbs/s256/path/to/image.jpg
String thumbPath(String path, int size) {
  final clean = path.startsWith('/') ? path.substring(1) : path;
  return 'thumbs/s$size/$clean';
}

int pickSquareSize(double logicalPx, double dpr, List<int> variants) {
  final need = (logicalPx * dpr).round();
  return variants.reduce((a, b) =>
      (need - a).abs() <= (need - b).abs() ? a : b);
}
