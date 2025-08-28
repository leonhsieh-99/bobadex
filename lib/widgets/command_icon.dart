import 'package:bobadex/config/constants.dart';
import 'package:flutter/material.dart';

class CommandIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int notificationCount;

  const CommandIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Badge(
            isLabelVisible: notificationCount != 0,
            backgroundColor: Colors.red,
            label: Text(
              notificationCount.toString(),
              style: Constants.badgeLabelStyle,
            ),
            child: Icon(icon, size: 26),
          ),
          const SizedBox(height: 0),
          if (label.isNotEmpty)
            Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
