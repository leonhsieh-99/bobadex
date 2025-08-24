import 'dart:convert';
import 'package:bobadex/notification_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<bool> exportMyData(BuildContext context) async {
  try {
    final client = Supabase.instance.client;

    final result = await client.rpc('export_my_data');

    if (result is! Map<String, dynamic>) {
      notify('Unexpected export format', SnackType.error);
      return false;
    }
    final Map<String, dynamic> data = result;

    final media = (data['media'] as List?) ?? [];
    for (final item in media) {
      final path = item['image_path'] as String?;
      if (path != null && path.isNotEmpty) {
        final public = client.storage.from('media-uploads').getPublicUrl(path);
        item['image_url'] = public;
      }
    }

    final pretty = const JsonEncoder.withIndent('  ').convert(data);
    await Clipboard.setData(ClipboardData(text: pretty));
    notify('Export copied to clipboard!', SnackType.success);
    return true;
  } on PostgrestException catch (e) {
    notify('Export failed: ${e.message}', SnackType.error);
    return false;
  } catch (e) {
    notify('Export failed: $e', SnackType.error);
    return false;
  }
}

