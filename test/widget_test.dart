import 'package:bobadex/ui/theme/boba_theme_builder.dart';
import 'package:bobadex/ui/theme/boba_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('default visual theme builds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: BobaThemeBuilder.build(
          BobaThemes.resolve(BobaThemes.defaultSlug),
        ),
        home: const Scaffold(body: Text('Bobadex')),
      ),
    );

    expect(find.text('Bobadex'), findsOneWidget);
  });
}
