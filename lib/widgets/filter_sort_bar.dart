import 'package:bobadex/ui/components/boba_chip.dart';
import 'package:bobadex/ui/components/boba_search_field.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';

class SortOption {
  final String key;
  final IconData icon;
  final String label;

  SortOption(this.key, this.icon, {String? label}) : label = label ?? key;
}

class FilterSortBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final List<SortOption> sortOptions;
  final ValueChanged<String> onSortSelected;
  final String initialSortKey;
  final bool initialAscending;
  final String searchHint;
  final EdgeInsetsGeometry padding;
  final double? searchHeight;

  const FilterSortBar({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    required this.sortOptions,
    required this.onSortSelected,
    this.initialSortKey = 'favorite',
    this.initialAscending = false,
    this.searchHint = 'Search brands',
    this.searchHeight,
    this.padding = const EdgeInsets.fromLTRB(
      BobaSpace.x4,
      BobaSpace.x2,
      BobaSpace.x4,
      BobaSpace.x2,
    ),
  });

  @override
  State<FilterSortBar> createState() => _FilterSortBarState();
}

class _FilterSortBarState extends State<FilterSortBar> {
  late String _selectedSortKey;
  late bool _isAscending;

  @override
  void initState() {
    super.initState();
    _selectedSortKey = widget.initialSortKey;
    _isAscending = widget.initialAscending;
  }

  void _emit() {
    widget.onSortSelected('$_selectedSortKey-${_isAscending ? 'asc' : 'desc'}');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Column(
        children: [
          BobaSearchField(
            controller: widget.controller,
            hint: widget.searchHint,
            height: widget.searchHeight,
            onChanged: widget.onSearchChanged,
          ),
          SizedBox(
            height: widget.searchHeight == null ? BobaSpace.x2 : BobaSpace.x1,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final opt in widget.sortOptions) ...[
                    BobaChip(
                      label: opt.label,
                      icon: Icon(opt.icon),
                      selected: _selectedSortKey == opt.key,
                      trailing: _selectedSortKey == opt.key
                          ? Icon(
                              _isAscending
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          if (_selectedSortKey == opt.key) {
                            _isAscending = !_isAscending;
                          } else {
                            _selectedSortKey = opt.key;
                          }
                        });
                        _emit();
                      },
                    ),
                    const SizedBox(width: BobaSpace.x2),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
