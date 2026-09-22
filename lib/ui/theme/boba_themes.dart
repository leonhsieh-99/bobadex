import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';

@immutable
class BobaThemeDefinition {
  const BobaThemeDefinition({
    required this.slug,
    required this.name,
    required this.tokens,
  });

  final String slug;
  final String name;
  final BobaTokens tokens;

  bool get isDark => tokens.isDark;
}

abstract final class BobaThemes {
  static const defaultSlug = 'classic_milk_tea';

  static const legacyThemeMap = <String, String>{
    'Brown': defaultSlug,
    'grey': defaultSlug,
    'Blue Grey': 'oolong',
    'Cyan': 'oolong',
    'Orange': 'thai_tea',
    'Yellow': 'mango',
    'Pink': 'strawberry',
    'Red': 'strawberry',
    'Purple': 'taro',
    'Deep Purple': 'taro',
    'Indigo': 'taro',
    'Green': 'matcha',
    'Teal': 'matcha',
  };

  static const light = <BobaThemeDefinition>[
    BobaThemeDefinition(
      slug: defaultSlug,
      name: 'Classic Milk Tea',
      tokens: BobaTokens(
        bg: Color(0xFFF5EEE3),
        surface: Color(0xFFFFFCF7),
        surfaceAlt: Color(0xFFEFE5D6),
        outline: Color(0xFFE3D6C5),
        ink: Color(0xFF2B1F17),
        inkMuted: Color(0xFF6F6157),
        inkFaint: Color(0xFFB8AB9E),
        accent: Color(0xFF8A5A3C),
        onAccent: Color(0xFFFFFFFF),
        accentSoft: Color(0xFFEBD9C7),
        accentInk: Color(0xFF6E4429),
        star: Color(0xFFE8B84A),
        starOutline: Color(0x996B4E1A),
        heart: Color(0xFFE07A7A),
        success: Color(0xFF4E8A5B),
        danger: Color(0xFFC4453F),
        shadow: Color(0x1F2B1F17),
        brightness: Brightness.light,
      ),
    ),
    BobaThemeDefinition(
      slug: 'matcha',
      name: 'Matcha',
      tokens: BobaTokens(
        bg: Color(0xFFEFF3E9),
        surface: Color(0xFFFBFDF8),
        surfaceAlt: Color(0xFFE4EBDC),
        outline: Color(0xFFD6DFCC),
        ink: Color(0xFF1E271C),
        inkMuted: Color(0xFF5F6B5A),
        inkFaint: Color(0xFFA9B3A3),
        accent: Color(0xFF5C7F4C),
        onAccent: Color(0xFFFFFFFF),
        accentSoft: Color(0xFFDAE7CF),
        accentInk: Color(0xFF46633A),
        star: Color(0xFFE8B84A),
        starOutline: Color(0x996B4E1A),
        heart: Color(0xFFE07A7A),
        success: Color(0xFF4E8A5B),
        danger: Color(0xFFC4453F),
        shadow: Color(0x1F2B1F17),
        brightness: Brightness.light,
      ),
    ),
    BobaThemeDefinition(
      slug: 'taro',
      name: 'Taro',
      tokens: BobaTokens(
        bg: Color(0xFFF2EEF7),
        surface: Color(0xFFFCFAFE),
        surfaceAlt: Color(0xFFE8E1F0),
        outline: Color(0xFFDCD3E6),
        ink: Color(0xFF27203A),
        inkMuted: Color(0xFF695F7A),
        inkFaint: Color(0xFFB0A7BF),
        accent: Color(0xFF7B5AA6),
        onAccent: Color(0xFFFFFFFF),
        accentSoft: Color(0xFFE5DAF1),
        accentInk: Color(0xFF5E4384),
        star: Color(0xFFE8B84A),
        starOutline: Color(0x996B4E1A),
        heart: Color(0xFFE07A7A),
        success: Color(0xFF4E8A5B),
        danger: Color(0xFFC4453F),
        shadow: Color(0x1F2B1F17),
        brightness: Brightness.light,
      ),
    ),
    BobaThemeDefinition(
      slug: 'strawberry',
      name: 'Strawberry',
      tokens: BobaTokens(
        bg: Color(0xFFFAEFF0),
        surface: Color(0xFFFFFAFA),
        surfaceAlt: Color(0xFFF3E1E3),
        outline: Color(0xFFEBD5D7),
        ink: Color(0xFF33201F),
        inkMuted: Color(0xFF7A625F),
        inkFaint: Color(0xFFBFA9A7),
        accent: Color(0xFFB84A60),
        onAccent: Color(0xFFFFFFFF),
        accentSoft: Color(0xFFF6D6DC),
        accentInk: Color(0xFF9E3F52),
        star: Color(0xFFE8B84A),
        starOutline: Color(0x996B4E1A),
        heart: Color(0xFFE07A7A),
        success: Color(0xFF4E8A5B),
        danger: Color(0xFFC4453F),
        shadow: Color(0x1F2B1F17),
        brightness: Brightness.light,
      ),
    ),
    BobaThemeDefinition(
      slug: 'thai_tea',
      name: 'Thai Tea',
      tokens: BobaTokens(
        bg: Color(0xFFFAF0E6),
        surface: Color(0xFFFFFAF5),
        surfaceAlt: Color(0xFFF2E2D3),
        outline: Color(0xFFEAD8C6),
        ink: Color(0xFF33241A),
        inkMuted: Color(0xFF7A6656),
        inkFaint: Color(0xFFBFAB9B),
        accent: Color(0xFFB85A2A),
        onAccent: Color(0xFFFFFFFF),
        accentSoft: Color(0xFFF5DBC8),
        accentInk: Color(0xFFA6512A),
        star: Color(0xFFE8B84A),
        starOutline: Color(0x996B4E1A),
        heart: Color(0xFFE07A7A),
        success: Color(0xFF4E8A5B),
        danger: Color(0xFFC4453F),
        shadow: Color(0x1F2B1F17),
        brightness: Brightness.light,
      ),
    ),
    BobaThemeDefinition(
      slug: 'mango',
      name: 'Mango',
      tokens: BobaTokens(
        bg: Color(0xFFFBF4E2),
        surface: Color(0xFFFFFCF4),
        surfaceAlt: Color(0xFFF3E8CF),
        outline: Color(0xFFEADDBE),
        ink: Color(0xFF33290F),
        inkMuted: Color(0xFF77693F),
        inkFaint: Color(0xFFBBAE86),
        accent: Color(0xFFD9A23A),
        onAccent: Color(0xFF2A2008),
        accentSoft: Color(0xFFF7E6B8),
        accentInk: Color(0xFF73520F),
        star: Color(0xFFD0931F),
        starOutline: Color(0x996B4E1A),
        heart: Color(0xFFE07A7A),
        success: Color(0xFF4E8A5B),
        danger: Color(0xFFC4453F),
        shadow: Color(0x1F2B1F17),
        brightness: Brightness.light,
      ),
    ),
    BobaThemeDefinition(
      slug: 'oolong',
      name: 'Oolong',
      tokens: BobaTokens(
        bg: Color(0xFFF1F1EE),
        surface: Color(0xFFFBFBF9),
        surfaceAlt: Color(0xFFE6E7E2),
        outline: Color(0xFFD8DAD4),
        ink: Color(0xFF22252A),
        inkMuted: Color(0xFF646A72),
        inkFaint: Color(0xFFA6ABB2),
        accent: Color(0xFF4E6F6C),
        onAccent: Color(0xFFFFFFFF),
        accentSoft: Color(0xFFD8E5E3),
        accentInk: Color(0xFF3B5654),
        star: Color(0xFFE8B84A),
        starOutline: Color(0x996B4E1A),
        heart: Color(0xFFE07A7A),
        success: Color(0xFF4E8A5B),
        danger: Color(0xFFC4453F),
        shadow: Color(0x1F2B1F17),
        brightness: Brightness.light,
      ),
    ),
  ];

  static const dark = <BobaThemeDefinition>[
    BobaThemeDefinition(
      slug: 'brown_sugar',
      name: 'Brown Sugar',
      tokens: BobaTokens(
        bg: Color(0xFF1B1411),
        surface: Color(0xFF251C18),
        surfaceAlt: Color(0xFF2F2520),
        outline: Color(0xFF3A2E28),
        ink: Color(0xFFF4EADF),
        inkMuted: Color(0xFFB5A493),
        inkFaint: Color(0xFF6E6055),
        accent: Color(0xFFDDA46A),
        onAccent: Color(0xFF1B1411),
        accentSoft: Color(0xFF3B2C22),
        accentInk: Color(0xFFE8B981),
        star: Color(0xFFF0C25A),
        starOutline: Color(0x00000000),
        heart: Color(0xFFEA8B8B),
        success: Color(0xFF6FB07C),
        danger: Color(0xFFE06B66),
        shadow: Color(0x80000000),
        brightness: Brightness.dark,
      ),
    ),
    BobaThemeDefinition(
      slug: 'black_sesame',
      name: 'Black Sesame',
      tokens: BobaTokens(
        bg: Color(0xFF121212),
        surface: Color(0xFF1B1B1B),
        surfaceAlt: Color(0xFF262626),
        outline: Color(0xFF3B3B3B),
        ink: Color(0xFFECECEC),
        inkMuted: Color(0xFFA3A3A3),
        inkFaint: Color(0xFF666666),
        accent: Color(0xFFCFC7BA),
        onAccent: Color(0xFF121212),
        accentSoft: Color(0xFF2C2A26),
        accentInk: Color(0xFFD9D2C6),
        star: Color(0xFFF0C25A),
        starOutline: Color(0x00000000),
        heart: Color(0xFFEA8B8B),
        success: Color(0xFF6FB07C),
        danger: Color(0xFFE06B66),
        shadow: Color(0x80000000),
        brightness: Brightness.dark,
      ),
    ),
    BobaThemeDefinition(
      slug: 'midnight_taro',
      name: 'Midnight Taro',
      tokens: BobaTokens(
        bg: Color(0xFF15121D),
        surface: Color(0xFF1E1A29),
        surfaceAlt: Color(0xFF2A2438),
        outline: Color(0xFF403753),
        ink: Color(0xFFEFEAF7),
        inkMuted: Color(0xFFADA4C0),
        inkFaint: Color(0xFF6A6280),
        accent: Color(0xFFB08BE0),
        onAccent: Color(0xFF15121D),
        accentSoft: Color(0xFF2F2542),
        accentInk: Color(0xFFC4A6EC),
        star: Color(0xFFF0C25A),
        starOutline: Color(0x00000000),
        heart: Color(0xFFEA8B8B),
        success: Color(0xFF6FB07C),
        danger: Color(0xFFE06B66),
        shadow: Color(0x80000000),
        brightness: Brightness.dark,
      ),
    ),
  ];

  static const all = <BobaThemeDefinition>[...light, ...dark];

  static String normalizeSlug(String? slug) {
    if (slug == null || slug.isEmpty) return defaultSlug;
    if (all.any((theme) => theme.slug == slug)) return slug;
    return legacyThemeMap[slug] ?? defaultSlug;
  }

  static bool isLegacySlug(String? slug) =>
      slug != null && legacyThemeMap.containsKey(slug);

  static BobaThemeDefinition resolve(String? slug) {
    final normalized = normalizeSlug(slug);
    return all.firstWhere((theme) => theme.slug == normalized);
  }
}
