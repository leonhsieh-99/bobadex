import 'package:bobadex/widgets/compact_text_row.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../state/user_state.dart';

class SortOption {
  final String key;
  final IconData icon;
  SortOption(this.key, this.icon);
}

class FilterSortBar extends StatelessWidget {
  const FilterSortBar({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    required this.sortOptions,
    required this.selectedSort,
    required this.onSortChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final List<SortOption> sortOptions;

  final String selectedSort;                 // e.g. 'rating-asc'
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final user = context.read<UserState>().current;

    // derive from selectedSort
    final parts = selectedSort.split('-');
    final selectedKey = parts.isNotEmpty ? parts[0] : (sortOptions.isNotEmpty ? sortOptions.first.key : '');
    final isAsc = parts.length > 1 && parts[1] == 'asc';

    return CompactTextRow(
      maxLength: 24,
      leftFlexStart: 2,
      leftFlexEnd: 9,
      rightFlex: 3,
      hintText: 'Search',
      textController: controller,
      onSearchChanged: onSearchChanged,
      child: Row(
        children: [
          // Asc/desc
          GestureDetector(
            onTap: () {
              final next = '$selectedKey-${isAsc ? 'desc' : 'asc'}';
              onSortChanged(next);
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                isAsc ? Icons.arrow_upward : Icons.arrow_downward,
                color: Constants.getThemeColor(user.themeSlug),
                size: 20,
              ),
            ),
          ),

          const SizedBox(height: 40, child: VerticalDivider(width: 1)),
          const SizedBox(width: 8),

          Flexible(
            flex: 4,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: sortOptions.map((opt) {
                  final selected = selectedKey == opt.key;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Icon(opt.icon, size: 16),
                      selected: selected,
                      backgroundColor: Constants.getThemeColor(user.themeSlug).shade50,
                      selectedColor: Constants.getThemeColor(user.themeSlug).shade100,
                      showCheckmark: false,
                      onSelected: (_) {
                        final next = '${opt.key}-${isAsc ? 'asc' : 'desc'}';
                        onSortChanged(next);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
