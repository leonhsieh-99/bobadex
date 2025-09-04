import 'package:supabase_flutter/supabase_flutter.dart';

String buildTransformedUrl({
  required String bucket,
  required String path,
  int? width,
  int? height,
  String resize = 'cover',
  int quality = 80,
  String? format,
}) {
  // Normalize path (no leading slash)
  final cleanPath = path.startsWith('/') ? path.substring(1) : path;

  final base = Supabase.instance.client.storage.from(bucket).getPublicUrl(cleanPath);
  final u = Uri.parse(base);

  // swap /object/public -> /render/image/public
  final renderPath = u.path.replaceFirst(
    '/storage/v1/object/public/',
    '/storage/v1/render/image/public/',
  );

  final qp = <String, String>{
    if (width != null) 'width': '$width',
    if (height != null) 'height': '$height',
    'resize': resize,
    'quality': '${quality.clamp(1, 100)}', // always valid
    if (format != null) 'format': format,
  };

  return Uri(
    scheme: u.scheme,
    host: u.host,
    path: renderPath,
    queryParameters: qp,
  ).toString();
}
