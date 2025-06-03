import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../state/user_state.dart';

class SortOption {
  final String key;
  final IconData icon;

  SortOption (this.key, this.icon);
}
class FilterSortBar extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final List<SortOption> sortOptions;
  final ValueChanged<String> onSortSelected;
  
  const FilterSortBar ({
    super.key,
    required this.onSearchChanged,
    required this.sortOptions,
    required this.onSortSelected,
  });

  @override
  State<FilterSortBar> createState () => _FilterSortBarState();
}

class _FilterSortBarState extends State<FilterSortBar> {
  String _selectedSortKey = '';
  bool _isAscending = false;

  @override
  void initState() {
    super.initState();
    if (widget.sortOptions.isNotEmpty) {
      _selectedSortKey = widget.sortOptions.first.key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserState>().user;
    return Row(
      children: [
        // search bar
        Expanded(
          flex: 4,
          child:SizedBox(
            height: 36,
            child: TextField(
              onChanged: widget.onSearchChanged,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),

        // Asc/desc icon
        GestureDetector(
          onTap: () {
            setState(() => _isAscending = !_isAscending);
            widget.onSortSelected(_selectedSortKey + (_isAscending ? '-asc' : '-desc'));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10), // very tight spacing
            child: Icon(
              _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: Constants.getThemeColor(user.themeSlug),
              size: 20,
            ),
          ),
        ),

        // Vertical divider
        const SizedBox(height: 40, child: VerticalDivider(width: 1)),

        // Sort option chips
        const SizedBox(width: 8),
        Flexible(
          flex: 4,
          child: Stack(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: widget.sortOptions.map((opt) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Icon(opt.icon, size: 16),
                        selected: _selectedSortKey == opt.key,
                        backgroundColor: Constants.getThemeColor(user.themeSlug).shade50,
                        selectedColor: Constants.getThemeColor(user.themeSlug).shade100,
                        showCheckmark: false,
                        onSelected: (_) {
                          setState(() => _selectedSortKey = opt.key);
                          widget.onSortSelected(opt.key + (_isAscending ? '-asc' : '-desc'));
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}