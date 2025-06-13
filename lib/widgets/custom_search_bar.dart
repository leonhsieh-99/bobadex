import 'package:bobadex/config/constants.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final user = context.watch<UserState>().user;
    final themeColor = Constants.getThemeColor(user.themeSlug);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SearchBar(
        controller: controller,
        hintText: hintText,
        constraints: BoxConstraints(
          minHeight: 40,
          maxHeight: 40,
        ),
        backgroundColor: WidgetStatePropertyAll(themeColor.shade100),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
        elevation: WidgetStatePropertyAll(0),
        side: WidgetStatePropertyAll(
          BorderSide(color: themeColor.shade200, width: 1),
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
