import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final SearchController controller;
  final String hintText;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SearchBar(
        controller: controller,
        hintText: hintText,
        constraints: BoxConstraints(minHeight: 40, maxHeight: 40),
        backgroundColor: WidgetStatePropertyAll(context.boba.surfaceAlt),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        ),
        elevation: WidgetStatePropertyAll(0),
        side: WidgetStatePropertyAll(
          BorderSide(color: context.boba.outline, width: 1),
        ),
        leading: const Icon(Icons.search),
        trailing: [
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => controller.clear(),
            ),
        ],
      ),
    );
  }
}
