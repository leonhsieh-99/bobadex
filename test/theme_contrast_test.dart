import 'dart:math' as math;

import 'package:bobadex/ui/theme/boba_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final lighter = math.max(a.computeLuminance(), b.computeLuminance());
  final darker = math.min(a.computeLuminance(), b.computeLuminance());
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('legacy theme slugs migrate to curated themes', () {
    expect(BobaThemes.normalizeSlug('Brown'), BobaThemes.defaultSlug);
    expect(BobaThemes.normalizeSlug('Deep Purple'), 'taro');
    expect(BobaThemes.normalizeSlug('Cyan'), 'oolong');
    expect(BobaThemes.normalizeSlug('unknown'), BobaThemes.defaultSlug);
  });

  for (final theme in BobaThemes.all) {
    group(theme.name, () {
      final tokens = theme.tokens;

      test('primary ink has strong contrast', () {
        expect(
          _contrast(tokens.ink, tokens.bg),
          greaterThanOrEqualTo(7),
          reason: 'ink on background',
        );
        expect(
          _contrast(tokens.ink, tokens.surface),
          greaterThanOrEqualTo(7),
          reason: 'ink on surface',
        );
      });

      test('secondary ink and controls are readable', () {
        expect(
          _contrast(tokens.inkMuted, tokens.surface),
          greaterThanOrEqualTo(4.5),
          reason: 'muted ink on surface',
        );
        expect(
          _contrast(tokens.onAccent, tokens.accent),
          greaterThanOrEqualTo(4.5),
          reason: 'text on accent',
        );
        expect(
          _contrast(tokens.accentInk, tokens.bg),
          greaterThanOrEqualTo(4.5),
          reason: 'accent ink on background',
        );
      });
    });
  }
}
