import 'package:bobadex/navigation.dart';
import 'package:bobadex/widgets/top_snack_bar.dart';
import 'package:flutter/material.dart';

enum SnackType { info, success, error, achievement }

// Place this function anywhere (eg. in a helpers file)
void showAppSnackBar(String message, {SnackType type = SnackType.info, int duration = 1900}) {
  final overlay = navigatorKey.currentState?.overlay;
  if (overlay == null) return;

  Color bgColor;
  IconData? icon;
  switch (type) {
    case SnackType.success:
      bgColor = Colors.green.shade600;
      icon = Icons.check_circle_rounded;
      break;
    case SnackType.error:
      bgColor = Colors.red.shade400;
      icon = Icons.error_outline;
      break;
    case SnackType.achievement:
      bgColor = Colors.amber.shade800;
      icon = Icons.emoji_events;
      break;
    case SnackType.info:
      bgColor = Colors.blue.shade500;
      icon = Icons.info_outline;
      break;
  }

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => TopSnackBar(
      message: message,
      backgroundColor: bgColor,
      icon: icon,
      onDismissed: () => entry.remove(),
      duration: Duration(milliseconds: duration),
    ),
  );
  overlay.insert(entry);
}