import 'package:bobadex/helpers/brand_lettering.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/widgets/icon_pic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _LetteringPalette {
  const _LetteringPalette(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

const _palettes = [
  _LetteringPalette(Color(0xFF2C1810), Color(0xFFF3E6D8)),
  _LetteringPalette(Color(0xFF1E3A34), Color(0xFFE4EFEA)),
  _LetteringPalette(Color(0xFF3D1F2B), Color(0xFFF6E8EE)),
  _LetteringPalette(Color(0xFF1C2A4A), Color(0xFFE8EEF7)),
  _LetteringPalette(Color(0xFF4A2E12), Color(0xFFF7E7C6)),
  _LetteringPalette(Color(0xFF2A2A2A), Color(0xFFEDE8E0)),
  _LetteringPalette(Color(0xFF143D3A), Color(0xFFDCEDEA)),
  _LetteringPalette(Color(0xFF4A1C1C), Color(0xFFF6E4E0)),
];

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
    final palette = _palettes[brandLetteringSeed(seed.isEmpty ? name : seed).abs() % _palettes.length];
    final side = expand ? double.infinity : size;
    final fontSize = expand
        ? null
        : size * (letters.length == 1 ? 0.46 : 0.38);

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

  const BrandMark({
    super.key,
    required this.name,
    this.slug,
    this.iconPath,
    this.size = 70,
    this.circular = true,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final useMascots = context.select<UserState, bool>((s) => s.current.useMascots);
    final hasIcon = iconPath != null && iconPath!.isNotEmpty;

    if (useMascots && hasIcon) {
      return IconPic(
        path: iconPath,
        size: size,
        circular: circular,
        fit: fit,
      );
    }

    return BrandLettering(
      name: name,
      seed: (slug != null && slug!.isNotEmpty) ? slug! : name,
      size: size,
      circular: circular,
    );
  }
}
