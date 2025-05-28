import 'package:flutter/material.dart';

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
    return Row(
      children: [
        // search bar
        Expanded(
          flex: 3,
          child: TextField(
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),

        // Asc/desc icon
        IconButton(
          icon: Icon(
            _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
            color: Colors.deepPurpleAccent,
          ),
          tooltip: _isAscending ? 'Sort ascending' : 'Sort descending',
          onPressed: () {
            setState(() => _isAscending = !_isAscending);
            widget.onSortSelected(_selectedSortKey + (_isAscending ? '-asc' : '-desc'));
          },
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
                padding: const EdgeInsets.only(right: 20),
                child: Row(
                  children: widget.sortOptions.map((opt) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Icon(opt.icon, size: 20),
                        selected: _selectedSortKey == opt.key,
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
              Positioned(
                right: 4,
                top: 0,
                bottom: 0,
                child: Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              )

            ],
          ),
        ),
      ],
    );
  }
}