import 'package:bobadex/auth/delete_account.dart';
import 'package:bobadex/helpers/export_data.dart';
import 'package:bobadex/runtime/app_runtime_controls.dart';
import 'package:bobadex/runtime/app_runtime_gate.dart';
import 'package:bobadex/ui/theme/boba_theme_builder.dart';
import 'package:bobadex/ui/theme/boba_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parser accepts schema v1 and drops unsafe store links', () {
    final controls = parseAppRuntimeControls({
      'schema_version': 1,
      'maintenance_enabled': false,
      'maintenance_message': '  Down for a minute.  ',
      'minimum_ios_build': 8,
      'minimum_android_build': 0,
      'update_message': '',
      'ios_update_url': 'https://apps.apple.com/app/id1',
      'android_update_url': 'http://play.google.com/store/apps/details?id=app',
    });
    expect(controls, isNotNull);
    expect(controls!.maintenanceMessage, 'Down for a minute.');
    expect(controls.updateMessage, defaultUpdateMessage);
    expect(controls.iosUpdateUrl?.host, 'apps.apple.com');
    expect(controls.androidUpdateUrl, isNull);
  });

  test('malformed controls are ignored', () {
    expect(parseAppRuntimeControls(null), isNull);
    expect(parseAppRuntimeControls({'schema_version': 2}), isNull);
    expect(
      parseAppRuntimeControls({
        'schema_version': 1,
        'maintenance_enabled': 'yes',
      }),
      isNull,
    );
  });

  test(
    'maintenance takes precedence and zero floors do not force an update',
    () {
      final controls = parseAppRuntimeControls({
        'schema_version': 1,
        'maintenance_enabled': true,
        'maintenance_message': 'Back soon',
        'minimum_ios_build': 99,
        'minimum_android_build': 99,
        'update_message': 'Update',
      });
      final decision = decideRuntimeAccess(
        controls: controls,
        platform: AppPlatformKind.ios,
        buildNumber: 1,
      );
      expect(decision.block, RuntimeBlock.maintenance);
      expect(decision.message, 'Back soon');

      final open = parseAppRuntimeControls({
        'schema_version': 1,
        'maintenance_enabled': false,
        'minimum_ios_build': 0,
        'minimum_android_build': 0,
        'update_message': 'Update',
      });
      expect(
        decideRuntimeAccess(
          controls: open,
          platform: AppPlatformKind.ios,
          buildNumber: 1,
        ).blocked,
        isFalse,
      );
      expect(
        decideRuntimeAccess(
          controls: open,
          platform: AppPlatformKind.other,
          buildNumber: 1,
        ).blocked,
        isFalse,
      );
    },
  );

  test('a build below the floor asks for an update', () {
    final controls = parseAppRuntimeControls({
      'schema_version': 1,
      'maintenance_enabled': false,
      'minimum_ios_build': 5,
      'minimum_android_build': 5,
      'update_message': 'Please update.',
      'ios_update_url': 'https://apps.apple.com/app/bobadex',
    });
    final below = decideRuntimeAccess(
      controls: controls,
      platform: AppPlatformKind.ios,
      buildNumber: 4,
    );
    expect(below.block, RuntimeBlock.update);
    expect(below.storeUrl, isNotNull);
    expect(
      decideRuntimeAccess(
        controls: controls,
        platform: AppPlatformKind.ios,
        buildNumber: 5,
      ).blocked,
      isFalse,
    );
    final android = decideRuntimeAccess(
      controls: controls,
      platform: AppPlatformKind.android,
      buildNumber: 1,
    );
    expect(android.storeUrl, isNull);
    expect(android.storeInstructions, contains('Google Play'));

    final missingLink = parseAppRuntimeControls({
      'schema_version': 1,
      'maintenance_enabled': false,
      'minimum_ios_build': 5,
      'minimum_android_build': 0,
      'update_message': 'Please update.',
    });
    expect(
      decideRuntimeAccess(
        controls: missingLink,
        platform: AppPlatformKind.ios,
        buildNumber: 1,
      ).storeUrl.toString(),
      iosAppStoreListing,
    );
  });

  test('delete failures use retry copy instead of a status phrase', () {
    expect(
      deleteFailureMessage(status: 401, details: {'error': 'unauthorized'}),
      contains('Sign in again'),
    );
    expect(
      deleteFailureMessage(
        status: 503,
        details: {'error': 'storage_cleanup_failed', 'retryable': true},
      ),
      contains('try again'),
    );
    expect(
      deleteFailureMessage(status: 503, details: 'Service Unavailable'),
      isNot(contains('Service Unavailable')),
    );
  });

  test('export keeps unknown keys and names the file from the timestamp', () {
    final data = withExportMediaUrls({
      'user': {'id': 'u1', 'note': '茶'},
      'shops': <dynamic>[],
      'media': [
        {'image_path': 'a/b.jpg', 'is_banner': true, 'extra': 1},
      ],
    }, (path) => 'https://cdn.example/$path');
    expect(data['user'], {'id': 'u1', 'note': '茶'});
    final media = (data['media'] as List).single as Map;
    expect(media['image_url'], 'https://cdn.example/a/b.jpg');
    expect(media['extra'], 1);
    expect(media['is_banner'], isTrue);
    expect(
      exportFilename(DateTime.utc(2026, 10, 23, 3, 4, 5)),
      'bobadex-export-20261023T030405Z.json',
    );
  });

  testWidgets('maintenance hides the app until the check allows it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: BobaThemeBuilder.build(
          BobaThemes.resolve(BobaThemes.defaultSlug),
        ),
        home: AppRuntimeGate(
          pollInterval: const Duration(days: 1),
          platform: AppPlatformKind.ios,
          buildNumber: 2,
          load: () async => parseAppRuntimeControls({
            'schema_version': 1,
            'maintenance_enabled': true,
            'maintenance_message': 'Back soon',
            'minimum_ios_build': 0,
            'minimum_android_build': 0,
            'update_message': 'Update',
          }),
          child: const Text('app body'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('app body'), findsNothing);
    expect(find.text('Back soon'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('an outdated build offers the App Store', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: BobaThemeBuilder.build(
          BobaThemes.resolve(BobaThemes.defaultSlug),
        ),
        home: AppRuntimeGate(
          pollInterval: const Duration(days: 1),
          platform: AppPlatformKind.ios,
          buildNumber: 1,
          load: () async => parseAppRuntimeControls({
            'schema_version': 1,
            'maintenance_enabled': false,
            'minimum_ios_build': 6,
            'minimum_android_build': 0,
            'update_message': 'Please update.',
          }),
          child: const Text('app body'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('app body'), findsNothing);
    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('Please update.'), findsOneWidget);
    expect(find.text('Update in the App Store'), findsOneWidget);
  });

  testWidgets('a failed runtime check leaves the app usable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: BobaThemeBuilder.build(
          BobaThemes.resolve(BobaThemes.defaultSlug),
        ),
        home: AppRuntimeGate(
          pollInterval: const Duration(days: 1),
          platform: AppPlatformKind.other,
          load: () async => throw Exception('offline'),
          child: const Text('app body'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('app body'), findsOneWidget);
  });
}
