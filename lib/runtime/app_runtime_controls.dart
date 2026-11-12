import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

enum AppPlatformKind { ios, android, other }

enum RuntimeBlock { none, maintenance, update }

class AppRuntimeControls {
  const AppRuntimeControls({
    required this.maintenanceEnabled,
    required this.maintenanceMessage,
    required this.minimumIosBuild,
    required this.minimumAndroidBuild,
    required this.updateMessage,
    this.iosUpdateUrl,
    this.androidUpdateUrl,
  });

  final bool maintenanceEnabled;
  final String maintenanceMessage;
  final int minimumIosBuild;
  final int minimumAndroidBuild;
  final String updateMessage;
  final Uri? iosUpdateUrl;
  final Uri? androidUpdateUrl;
}

class RuntimeDecision {
  const RuntimeDecision._({
    required this.block,
    required this.message,
    this.storeUrl,
    this.storeActionLabel,
    this.storeInstructions,
  });

  const RuntimeDecision.allow() : this._(block: RuntimeBlock.none, message: '');

  final RuntimeBlock block;
  final String message;
  final Uri? storeUrl;
  final String? storeActionLabel;
  final String? storeInstructions;

  bool get blocked => block != RuntimeBlock.none;
}

const defaultMaintenanceMessage =
    'Bobadex is temporarily unavailable. Please try again shortly.';
const defaultUpdateMessage = 'Please update Bobadex to continue.';

/// Public listing. Used when the server has not stored its own https URL.
const iosAppStoreListing = 'https://apps.apple.com/app/id6752920262';

const runtimeControlsTimeout = Duration(seconds: 3);

AppRuntimeControls? parseAppRuntimeControls(Object? raw) {
  if (raw is! Map) return null;
  final json = Map<String, dynamic>.from(raw);
  if (json['schema_version'] != 1) return null;
  if (json['maintenance_enabled'] is! bool) return null;

  return AppRuntimeControls(
    maintenanceEnabled: json['maintenance_enabled'] as bool,
    maintenanceMessage: _message(
      json['maintenance_message'],
      defaultMaintenanceMessage,
    ),
    minimumIosBuild: _buildFloor(json['minimum_ios_build']),
    minimumAndroidBuild: _buildFloor(json['minimum_android_build']),
    updateMessage: _message(json['update_message'], defaultUpdateMessage),
    iosUpdateUrl: _storeUrl(json['ios_update_url'], 'apps.apple.com'),
    androidUpdateUrl: _storeUrl(json['android_update_url'], 'play.google.com'),
  );
}

RuntimeDecision decideRuntimeAccess({
  required AppRuntimeControls? controls,
  required AppPlatformKind platform,
  required int? buildNumber,
}) {
  if (controls == null) return const RuntimeDecision.allow();
  if (controls.maintenanceEnabled) {
    return RuntimeDecision._(
      block: RuntimeBlock.maintenance,
      message: controls.maintenanceMessage,
    );
  }

  final floor = switch (platform) {
    AppPlatformKind.ios => controls.minimumIosBuild,
    AppPlatformKind.android => controls.minimumAndroidBuild,
    AppPlatformKind.other => 0,
  };
  if (platform == AppPlatformKind.other || floor <= 0) {
    return const RuntimeDecision.allow();
  }
  if (buildNumber == null || buildNumber >= floor) {
    return const RuntimeDecision.allow();
  }

  final url = switch (platform) {
    AppPlatformKind.ios =>
      controls.iosUpdateUrl ?? Uri.parse(iosAppStoreListing),
    AppPlatformKind.android => controls.androidUpdateUrl,
    AppPlatformKind.other => null,
  };
  final storeName = platform == AppPlatformKind.ios
      ? 'the App Store'
      : 'Google Play';
  return RuntimeDecision._(
    block: RuntimeBlock.update,
    message: controls.updateMessage,
    storeUrl: url,
    storeActionLabel: url == null ? null : 'Update in $storeName',
    storeInstructions: url == null
        ? 'Open $storeName and search for Bobadex.'
        : null,
  );
}

Future<AppRuntimeControls?> loadAppRuntimeControls({
  SupabaseClient? client,
  Duration timeout = runtimeControlsTimeout,
}) async {
  try {
    final raw = await (client ?? Supabase.instance.client)
        .rpc('get_app_runtime_controls')
        .timeout(timeout);
    return parseAppRuntimeControls(raw);
  } catch (_) {
    return null;
  }
}

String _message(Object? value, String fallback) {
  if (value is! String) return fallback;
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

int _buildFloor(Object? value) {
  if (value is int) return value < 0 ? 0 : value;
  if (value is num) return value.toInt() < 0 ? 0 : value.toInt();
  return 0;
}

Uri? _storeUrl(Object? value, String host) {
  if (value is! String || value.trim().isEmpty) return null;
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.scheme != 'https' || uri.host != host) return null;
  return uri;
}
