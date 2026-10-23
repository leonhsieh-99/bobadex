import 'dart:convert';
import 'dart:io';

import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/ui/components/boba_button.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ExportChoice { share, copy }

var _exportInFlight = false;

String exportFilename(DateTime utc) {
  final local = utc.toUtc();
  String two(int value) => value.toString().padLeft(2, '0');
  final stamp =
      '${local.year}${two(local.month)}${two(local.day)}T${two(local.hour)}${two(local.minute)}${two(local.second)}Z';
  return 'bobadex-export-$stamp.json';
}

/// Adds public media URLs without dropping other keys on each media row.
Map<String, dynamic> withExportMediaUrls(
  Map<String, dynamic> data,
  String Function(String path) urlFor,
) {
  final media = data['media'];
  if (media is! List) return data;
  for (final item in media) {
    if (item is! Map) continue;
    final path = item['image_path'];
    if (path is String && path.isNotEmpty) {
      item['image_url'] = urlFor(path);
    }
  }
  return data;
}

Future<void> promptExportMyData(BuildContext context) async {
  if (_exportInFlight) return;
  final choice = await showModalBottomSheet<ExportChoice>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          BobaSpace.x5,
          0,
          BobaSpace.x5,
          BobaSpace.x6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Export your data',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: BobaSpace.x2),
            Text(
              'Save a JSON file, or copy it if you would rather paste it somewhere.',
              style: Theme.of(sheetContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: BobaSpace.x4),
            BobaButton(
              label: 'Save and share',
              expanded: true,
              onPressed: () =>
                  Navigator.of(sheetContext).pop(ExportChoice.share),
            ),
            const SizedBox(height: BobaSpace.x2),
            BobaButton(
              label: 'Copy JSON',
              expanded: true,
              variant: BobaButtonVariant.secondary,
              onPressed: () =>
                  Navigator.of(sheetContext).pop(ExportChoice.copy),
            ),
          ],
        ),
      );
    },
  );
  if (choice == null || !context.mounted) return;

  _exportInFlight = true;
  try {
    final client = Supabase.instance.client;
    final result = await client.rpc('export_my_data');
    if (result is! Map) {
      notify('Unexpected export format', SnackType.error);
      return;
    }
    final data = withExportMediaUrls(
      Map<String, dynamic>.from(result),
      (path) => client.storage.from('media-uploads').getPublicUrl(path),
    );
    final pretty = const JsonEncoder.withIndent('  ').convert(data);
    if (!context.mounted) return;
    if (choice == ExportChoice.copy) {
      await Clipboard.setData(ClipboardData(text: pretty));
      notify('Export copied', SnackType.success);
      return;
    }
    await _shareExport(pretty);
  } on PostgrestException catch (e) {
    notify('Export failed: ${e.message}', SnackType.error);
  } catch (_) {
    notify('Export failed. Please try again.', SnackType.error);
  } finally {
    _exportInFlight = false;
  }
}

Future<void> _shareExport(String pretty) async {
  final name = exportFilename(DateTime.now());
  final file = File('${(await getTemporaryDirectory()).path}/$name');
  try {
    await file.writeAsString(pretty, flush: true);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json', name: name)],
      ),
    );
    if (result.status == ShareResultStatus.dismissed) {
      notify('Share canceled', SnackType.info);
      return;
    }
    if (result.status == ShareResultStatus.unavailable) {
      notify('Could not open the share sheet.', SnackType.error);
    }
  } catch (_) {
    notify('Could not save the export file.', SnackType.error);
  }
}
