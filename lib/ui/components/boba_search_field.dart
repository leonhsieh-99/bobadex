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
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(Icons.search_rounded, color: context.boba.inkMuted),
        suffixIcon:
            trailing ??
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                  icon: const Icon(Icons.close_rounded),
                );
              },
            ),
      ),
    );
  }
}
