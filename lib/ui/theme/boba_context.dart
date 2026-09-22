import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:bobadex/ui/theme/boba_typography.dart';
import 'package:flutter/material.dart';

extension BobaContext on BuildContext {
  BobaTokens get boba => Theme.of(this).extension<BobaTokens>()!;

  BobaTextStyles get bobaText => BobaTextStyles(boba);
}

class BobaTextStyles {
  const BobaTextStyles(this.tokens);

  final BobaTokens tokens;

  TextStyle numeral({double? fontSize}) =>
      BobaTypography.numeral(tokens, fontSize: fontSize);

  TextStyle get empty => TextStyle(
    fontSize: 16,
    color: tokens.inkMuted,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w400,
  );

  TextStyle get badge => TextStyle(
    fontSize: 10,
    color: tokens.onAccent,
    fontWeight: FontWeight.w600,
  );
}
