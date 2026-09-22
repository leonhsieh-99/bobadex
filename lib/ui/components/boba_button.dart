import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';

enum BobaButtonVariant { primary, secondary, tertiary, danger }

enum BobaButtonSize { medium, small }

class BobaButton extends StatelessWidget {
  const BobaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = BobaButtonVariant.primary,
    this.size = BobaButtonSize.medium,
    this.icon,
    this.loading = false,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final BobaButtonVariant variant;
  final BobaButtonSize size;
  final Widget? icon;
  final bool loading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final height = size == BobaButtonSize.small ? 36.0 : 48.0;
    final padding = EdgeInsets.symmetric(
      horizontal: size == BobaButtonSize.small ? BobaSpace.x3 : BobaSpace.x5,
    );
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(BobaSize.tap, height)),
      padding: WidgetStatePropertyAll(padding),
    );
    final action = loading ? null : onPressed;
    final content = AnimatedSwitcher(
      duration: BobaMotion.fast,
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color:
                    variant == BobaButtonVariant.primary ||
                        variant == BobaButtonVariant.danger
                    ? tokens.onAccent
                    : tokens.accent,
              ),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  IconTheme.merge(
                    data: const IconThemeData(size: 18),
                    child: icon!,
                  ),
                  const SizedBox(width: BobaSpace.x2),
                ],
                Text(label),
              ],
            ),
    );

    final button = switch (variant) {
      BobaButtonVariant.primary => FilledButton(
        onPressed: action,
        style: style,
        child: content,
      ),
      BobaButtonVariant.secondary => OutlinedButton(
        onPressed: action,
        style: style,
        child: content,
      ),
      BobaButtonVariant.tertiary => TextButton(
        onPressed: action,
        style: style,
        child: content,
      ),
      BobaButtonVariant.danger => FilledButton(
        onPressed: action,
        style: style.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled)
                ? tokens.surfaceAlt
                : tokens.danger;
          }),
        ),
        child: content,
      ),
    };

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
