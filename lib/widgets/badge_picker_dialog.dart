import 'package:bobadex/models/achievement.dart';
// import 'package:bobadex/state/achievements_state.dart';
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

class BadgePickerDialog extends StatefulWidget {
  final List<Achievement> badges;
  final List<Achievement> pinnedBadges;
  final Function(List<String> selectedIds) onSave;
  final int maxSelect;

  const BadgePickerDialog({
    super.key,
    required this.badges,
    required this.pinnedBadges,
    required this.onSave,
    this.maxSelect = 4,
  });

  @override
  State<BadgePickerDialog> createState() => _BadgePickerDialogState();
}

class _BadgePickerDialogState extends State<BadgePickerDialog> {
  late Set<String> selected;

  @override
  void initState() {
    super.initState();
    selected = widget.pinnedBadges.map((b) => b.id).toSet();
  }

@override
Widget build(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;

  final dialogMaxHeight = screenHeight * 0.5;
  final dialogMaxWidth = screenWidth * 0.9;

  return AlertDialog(
    title: Text('Pin your badges (up to ${widget.maxSelect})'),
    content: SizedBox(
      // Explicitly set both width and height to avoid intrinsic measurement
      width: dialogMaxWidth,
      height: dialogMaxHeight,
      child: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 20,
        childAspectRatio: 0.8,
        children: widget.badges.map((a) {
          final isSelected = selected.contains(a.id);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  selected.remove(a.id);
                } else if (selected.length < widget.maxSelect) {
                  selected.add(a.id);
                }
              });
            },
            child: Tooltip(
              message: a.description,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: isSelected ? Colors.amber : Colors.grey, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      backgroundImage: AssetImage((a.iconPath != null && a.iconPath!.isNotEmpty)
                        ? a.iconPath!
                        : 'lib/assets/badges/default_badge.png'
                      ),
                      radius: 36,
                      child: isSelected
                          ? Icon(Icons.check_circle, color: Colors.amberAccent, size: 24)
                          : null,
                    ),
                  ),
                  Text(
                    a.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 9,
                    ),
                  )
                ]
              ),
            )
          );
        }).toList(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () {
          widget.onSave(selected.toList());
        },
        child: Text('Save'),
      ),
    ],
  );
}

}
