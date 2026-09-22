import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_theme_builder.dart';
import 'package:bobadex/ui/theme/boba_themes.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';

class ThemePreviewCard extends StatelessWidget {
  const ThemePreviewCard({
    super.key,
    required this.definition,
    required this.selected,
    required this.onTap,
  });

  final BobaThemeDefinition definition;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final previewTheme = BobaThemeBuilder.build(definition);
    return Semantics(
      selected: selected,
      button: true,
      label: '${definition.name} theme',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: BobaMotion.fast,
          padding: const EdgeInsets.all(BobaSpace.x1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(BobaRadius.lg + BobaSpace.x1),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: BobaStroke.focus,
            ),
          ),
          child: Theme(
            data: previewTheme,
            child: Builder(
              builder: (previewContext) {
                final tokens = previewContext.boba;
                final swatches = [
                  tokens.bg,
                  tokens.surface,
                  tokens.accent,
                  tokens.ink,
                ];
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.bg,
                    borderRadius: BorderRadius.circular(BobaRadius.lg),
                    border: Border.all(
                      color: tokens.outline,
                      width: BobaStroke.card,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(BobaSpace.x3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              for (var i = 0; i < swatches.length; i++) ...[
                                Expanded(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: swatches[i],
                                      borderRadius: BorderRadius.horizontal(
                                        left: i == 0
                                            ? const Radius.circular(
                                                BobaRadius.sm,
                                              )
                                            : Radius.zero,
                                        right: i == swatches.length - 1
                                            ? const Radius.circular(
                                                BobaRadius.sm,
                                              )
                                            : Radius.zero,
                                      ),
                                      border: Border.all(
                                        color: tokens.outline.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: BobaStroke.hairline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: BobaSpace.x2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                definition.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: previewTheme.textTheme.labelLarge
                                    ?.copyWith(color: tokens.ink),
                              ),
                            ),
                            if (selected)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: tokens.accent,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
