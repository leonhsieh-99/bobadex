import 'package:bobadex/helpers/brand_lettering.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:bobadex/widgets/icon_pic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _LetteringPalette {
  const _LetteringPalette(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

const _lightPalettes = [
  _LetteringPalette(Color(0xFFE9D8C8), Color(0xFF4A3428)),
  _LetteringPalette(Color(0xFFD7E5CC), Color(0xFF3A4A32)),
  _LetteringPalette(Color(0xFFE6D6EF), Color(0xFF4A3A58)),
  _LetteringPalette(Color(0xFFF0D6DA), Color(0xFF5A3438)),
  _LetteringPalette(Color(0xFFF0DCC8), Color(0xFF5A3E28)),
  _LetteringPalette(Color(0xFFF2E4C0), Color(0xFF5A4820)),
  _LetteringPalette(Color(0xFFDCE2E0), Color(0xFF3A4444)),
  _LetteringPalette(Color(0xFFEBD4CC), Color(0xFF5A3834)),
];

const _darkPalettes = [
  _LetteringPalette(Color(0xFF3A281E), Color(0xFFF3E6D8)),
  _LetteringPalette(Color(0xFF243832), Color(0xFFE4EFEA)),
  _LetteringPalette(Color(0xFF3A2430), Color(0xFFF6E8EE)),
  _LetteringPalette(Color(0xFF243044), Color(0xFFE8EEF7)),
  _LetteringPalette(Color(0xFF3E2C18), Color(0xFFF7E7C6)),
  _LetteringPalette(Color(0xFF2E2E2E), Color(0xFFEDE8E0)),
  _LetteringPalette(Color(0xFF1E3836), Color(0xFFDCEDEA)),
  _LetteringPalette(Color(0xFF3E2222), Color(0xFFF6E4E0)),
];

_LetteringPalette _brandLetteringPalette(BuildContext context, String seed) {
  final catalog = Theme.of(context).brightness == Brightness.dark
      ? _darkPalettes
      : _lightPalettes;
  return catalog[brandLetteringSeed(seed).abs() % catalog.length];
}

/// Minimalist brand mark from a name. Color and letters are deterministic.
class BrandLettering extends StatelessWidget {
  final String name;
  final String seed;
  final double size;
  final bool circular;
  final bool expand;

  const BrandLettering({
    super.key,
    required this.name,
    required this.seed,
    this.size = 70,
    this.circular = true,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final letters = brandLettering(name);
    final palette = _brandLetteringPalette(context, seed.isEmpty ? name : seed);
    final side = expand ? double.infinity : size;
    final fontSize = expand ? null : size * (letters.length == 1 ? 0.46 : 0.38);

    final mark = ColoredBox(
      color: palette.background,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              letters,
              style: TextStyle(
                color: palette.foreground,
                fontSize: fontSize ?? 42,
                fontWeight: FontWeight.w700,
                letterSpacing: letters.length == 1 ? 0 : 1.2,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );

    return SizedBox(
      width: side,
      height: side,
      child: circular
          ? ClipOval(child: mark)
          : ClipRRect(borderRadius: BorderRadius.circular(12), child: mark),
    );
  }
}

/// Brand visual that follows the signed-in user's mascot setting.
class BrandMark extends StatelessWidget {
  final String name;
  final String? slug;
  final String? iconPath;
  final double size;
  final bool circular;
  final BoxFit fit;
  final bool silhouette;
  final bool showAccentRing;

  const BrandMark({
    super.key,
    required this.name,
    this.slug,
    this.iconPath,
    this.size = 70,
    this.circular = true,
    this.fit = BoxFit.cover,
    this.silhouette = false,
    this.showAccentRing = false,
  });

  static const _accentPalette = <Color>[
    Color(0xFF9B6847),
    Color(0xFF5F8067),
    Color(0xFF9B6173),
    Color(0xFF6276A0),
    Color(0xFFB08045),
    Color(0xFF6D6A65),
    Color(0xFF4F817D),
    Color(0xFFA35C55),
  ];

  static Color accentFor(String seed) {
    final hash = brandLetteringSeed(seed).abs();
    return _accentPalette[hash % _accentPalette.length];
  }

  @override
  Widget build(BuildContext context) {
    final useMascots = context.select<UserState, bool>(
      (s) => s.current.useMascots,
    );
    final hasIcon = iconPath != null && iconPath!.isNotEmpty;

    Widget mark;
    if (silhouette && useMascots && hasIcon) {
      mark = Opacity(
        opacity: 0.45,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: IconPic(
            path: iconPath,
            size: size,
            circular: circular,
            fit: fit,
          ),
        ),
      );
    } else if (silhouette) {
      final tokens = context.boba;
      mark = Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tokens.surfaceAlt,
          shape: circular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circular ? null : BorderRadius.circular(BobaRadius.sm),
        ),
        child: Text(
          brandLettering(name),
          style: TextStyle(
            color: tokens.inkFaint,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else if (useMascots && hasIcon) {
      mark = IconPic(path: iconPath, size: size, circular: circular, fit: fit);
    } else {
      mark = BrandLettering(
        name: name,
        seed: (slug != null && slug!.isNotEmpty) ? slug! : name,
        size: size,
        circular: circular,
      );
    }

    if (!showAccentRing) return mark;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(BobaRadius.md),
        border: Border.all(
          color: accentFor((slug?.isNotEmpty ?? false) ? slug! : name),
          width: BobaStroke.focus,
        ),
      ),
      child: mark,
    );
  }
}
