import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';

class BobaChip extends StatelessWidget {
  const BobaChip({
    super.key,
    required this.label,
    this.icon,
    this.trailing,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final Widget? icon;
  final Widget? trailing;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final foreground = selected ? tokens.accentInk : tokens.inkMuted;
    return Material(
      color: selected ? tokens.accentSoft : tokens.surfaceAlt,
      borderRadius: BorderRadius.circular(BobaRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BobaRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BobaSpace.x3,
            vertical: BobaSpace.x2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                IconTheme.merge(
                  data: IconThemeData(size: 16, color: foreground),
                  child: icon!,
                ),
                const SizedBox(width: BobaSpace.x1),
              ],
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: foreground),
              ),
              if (trailing != null) ...[
                const SizedBox(width: BobaSpace.x1),
                IconTheme.merge(
                  data: IconThemeData(size: 15, color: foreground),
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
