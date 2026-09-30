import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:flutter/material.dart';

class BobaSearchField extends StatelessWidget {
  const BobaSearchField({
    super.key,
    required this.controller,
    this.hint = 'Search',
    this.onChanged,
    this.trailing,
    this.focusNode,
    this.height,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;
  final FocusNode? focusNode;

  /// Overrides the theme field height. Leave unset for the default form field.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final compact = height != null;
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: compact ? 14 : null,
      ),
      decoration: InputDecoration(
        hintText: hint,
        isDense: compact,
        contentPadding: compact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 0)
            : null,
        constraints: compact
            ? BoxConstraints(minHeight: height!, maxHeight: height!)
            : null,
        prefixIcon: Icon(
          Icons.search_rounded,
          size: compact ? 18 : null,
          color: context.boba.inkMuted,
        ),
        prefixIconConstraints: compact
            ? BoxConstraints(minWidth: 36, minHeight: height!)
            : null,
        suffixIconConstraints: compact
            ? BoxConstraints(minWidth: 36, minHeight: height!)
            : null,
        suffixIcon:
            trailing ??
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  tooltip: 'Clear search',
                  visualDensity: compact ? VisualDensity.compact : null,
                  padding: compact ? EdgeInsets.zero : null,
                  constraints: compact
                      ? BoxConstraints(minWidth: 36, minHeight: height!)
                      : null,
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                  icon: Icon(Icons.close_rounded, size: compact ? 18 : null),
                );
              },
            ),
      ),
    );
    if (!compact) return field;
    return SizedBox(height: height, child: field);
  }
}
