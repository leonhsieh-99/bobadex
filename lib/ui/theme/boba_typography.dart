import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class BobaTypography {
  static TextTheme textTheme(BobaTokens tokens) {
    final inter = GoogleFonts.interTextTheme(
      ThemeData(brightness: tokens.brightness).textTheme,
    ).apply(bodyColor: tokens.ink, displayColor: tokens.ink);

    return inter.copyWith(
      displaySmall: GoogleFonts.fraunces(
        fontSize: 32,
        height: 38 / 32,
        fontWeight: FontWeight.w600,
        color: tokens.ink,
      ),
      headlineSmall: GoogleFonts.fraunces(
        fontSize: 24,
        height: 30 / 24,
        fontWeight: FontWeight.w600,
        color: tokens.ink,
      ),
      titleMedium: GoogleFonts.fraunces(
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w600,
        color: tokens.ink,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w400,
        color: tokens.ink,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: tokens.ink,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 13,
        height: 16 / 13,
        fontWeight: FontWeight.w600,
        color: tokens.ink,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        color: tokens.inkMuted,
      ),
    );
  }

  static TextStyle numeral(BobaTokens tokens, {double? fontSize}) {
    return GoogleFonts.fraunces(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: tokens.ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
