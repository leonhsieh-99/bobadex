import 'package:flutter/material.dart';

@immutable
class BobaTokens extends ThemeExtension<BobaTokens> {
  const BobaTokens({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.outline,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.accentInk,
    required this.star,
    required this.starOutline,
    required this.heart,
    required this.success,
    required this.danger,
    required this.shadow,
    required this.brightness,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color outline;
  final Color ink;
  final Color inkMuted;
  final Color inkFaint;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color accentInk;
  final Color star;
  final Color starOutline;
  final Color heart;
  final Color success;
  final Color danger;
  final Color shadow;
  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;
  Color get onImage => const Color(0xFFFFFFFF);
  Color get imageScrim => const Color(0xFF000000);

  @override
  BobaTokens copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? outline,
    Color? ink,
    Color? inkMuted,
    Color? inkFaint,
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? accentInk,
    Color? star,
    Color? starOutline,
    Color? heart,
    Color? success,
    Color? danger,
    Color? shadow,
    Brightness? brightness,
  }) {
    return BobaTokens(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      outline: outline ?? this.outline,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkFaint: inkFaint ?? this.inkFaint,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentSoft: accentSoft ?? this.accentSoft,
      accentInk: accentInk ?? this.accentInk,
      star: star ?? this.star,
      starOutline: starOutline ?? this.starOutline,
      heart: heart ?? this.heart,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      shadow: shadow ?? this.shadow,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  BobaTokens lerp(covariant BobaTokens? other, double t) {
    if (other == null) return this;
    return BobaTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      star: Color.lerp(star, other.star, t)!,
      starOutline: Color.lerp(starOutline, other.starOutline, t)!,
      heart: Color.lerp(heart, other.heart, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      brightness: t < 0.5 ? brightness : other.brightness,
    );
  }
}

abstract final class BobaRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

abstract final class BobaSpace {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x7 = 32;
  static const double x8 = 40;
}

abstract final class BobaStroke {
  static const double hairline = 0.5;
  static const double card = 1;
  static const double focus = 2;
}

abstract final class BobaMotion {
  static const Duration press = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration stamp = Duration(milliseconds: 500);
}

abstract final class BobaSize {
  static const double tap = 44;
  static const double markSm = 32;
  static const double markMd = 44;
  static const double markLg = 64;
  static const double markXl = 96;
  static const double avatarSm = 24;
  static const double avatarMd = 40;
  static const double avatarLg = 56;
  static const double avatarXl = 88;
}

abstract final class BobaShadow {
  static BoxShadow floating(BobaTokens tokens) => BoxShadow(
    color: tokens.shadow,
    blurRadius: 24,
    offset: const Offset(0, 8),
  );
}
