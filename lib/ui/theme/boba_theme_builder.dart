import 'package:bobadex/ui/theme/boba_themes.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:bobadex/ui/theme/boba_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class BobaThemeBuilder {
  static ThemeData build(BobaThemeDefinition definition) {
    final tokens = definition.tokens;
    final textTheme = BobaTypography.textTheme(tokens);
    final colorScheme = ColorScheme(
      brightness: tokens.brightness,
      primary: tokens.accent,
      onPrimary: tokens.onAccent,
      primaryContainer: tokens.accentSoft,
      onPrimaryContainer: tokens.accentInk,
      secondary: tokens.accent,
      onSecondary: tokens.onAccent,
      secondaryContainer: tokens.accentSoft,
      onSecondaryContainer: tokens.accentInk,
      error: tokens.danger,
      onError: tokens.isDark ? tokens.bg : const Color(0xFFFFFFFF),
      surface: tokens.surface,
      onSurface: tokens.ink,
      outline: tokens.outline,
      outlineVariant: tokens.outline,
      shadow: tokens.shadow,
      scrim: tokens.ink,
      inverseSurface: tokens.ink,
      onInverseSurface: tokens.surface,
      inversePrimary: tokens.accentSoft,
    );

    final pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(BobaRadius.pill),
    );
    final card = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(BobaRadius.lg),
      side: BorderSide(color: tokens.outline, width: BobaStroke.card),
    );
    final input = OutlineInputBorder(
      borderRadius: BorderRadius.circular(BobaRadius.md),
      borderSide: BorderSide.none,
    );
    final focusedInput = input.copyWith(
      borderSide: BorderSide(color: tokens.accent, width: BobaStroke.focus),
    );

    return ThemeData(
      brightness: tokens.brightness,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.bg,
      canvasColor: tokens.bg,
      dividerColor: tokens.outline,
      disabledColor: tokens.inkFaint,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: tokens.ink),
      primaryIconTheme: IconThemeData(color: tokens.ink),
      extensions: <ThemeExtension<dynamic>>[tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.bg,
        foregroundColor: tokens.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
        systemOverlayStyle: tokens.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: card,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BobaRadius.xl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(BobaRadius.xl),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.accent,
          foregroundColor: tokens.onAccent,
          disabledBackgroundColor: tokens.surfaceAlt,
          disabledForegroundColor: tokens.inkFaint,
          minimumSize: const Size(BobaSize.tap, 48),
          padding: const EdgeInsets.symmetric(horizontal: BobaSpace.x5),
          shape: pill,
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.accent,
          foregroundColor: tokens.onAccent,
          disabledBackgroundColor: tokens.surfaceAlt,
          disabledForegroundColor: tokens.inkFaint,
          minimumSize: const Size(BobaSize.tap, 48),
          elevation: 0,
          shape: pill,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.ink,
          minimumSize: const Size(BobaSize.tap, 48),
          side: BorderSide(color: tokens.outline),
          shape: pill,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.accentInk,
          backgroundColor: Colors.transparent,
          minimumSize: const Size(BobaSize.tap, BobaSize.tap),
          shape: pill,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BobaSpace.x4,
          vertical: BobaSpace.x3,
        ),
        border: input,
        enabledBorder: input,
        disabledBorder: input,
        focusedBorder: focusedInput,
        errorBorder: input.copyWith(
          borderSide: BorderSide(color: tokens.danger),
        ),
        focusedErrorBorder: focusedInput.copyWith(
          borderSide: BorderSide(color: tokens.danger, width: BobaStroke.focus),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: tokens.inkMuted),
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.inkFaint),
        errorStyle: textTheme.labelSmall?.copyWith(color: tokens.danger),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surfaceAlt,
        selectedColor: tokens.accentSoft,
        disabledColor: tokens.surfaceAlt,
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: tokens.accentInk,
        ),
        side: BorderSide.none,
        shape: pill,
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? tokens.accentInk
                : tokens.inkMuted;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? tokens.accentSoft
                : tokens.surface;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: tokens.outline)),
          shape: WidgetStatePropertyAll(pill),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.outline,
        thickness: BobaStroke.card,
        space: BobaStroke.card,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: tokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BobaRadius.md),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: tokens.outline,
        indicatorColor: tokens.accent,
        labelColor: tokens.ink,
        unselectedLabelColor: tokens.inkMuted,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.accent,
        linearTrackColor: tokens.surfaceAlt,
        circularTrackColor: tokens.surfaceAlt,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? tokens.onAccent
              : tokens.inkFaint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? tokens.accent
              : tokens.surfaceAlt;
        }),
        trackOutlineColor: WidgetStatePropertyAll(tokens.outline),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: tokens.inkMuted,
        textColor: tokens.ink,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: tokens.inkMuted,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BobaRadius.md),
        ),
      ),
    );
  }
}
