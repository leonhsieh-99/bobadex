import 'package:bobadex/config/constants.dart';
import 'package:bobadex/navigation.dart';
import 'package:bobadex/widgets/top_snack_bar.dart';
import 'package:flutter/material.dart';

enum SnackType { info, success, error, achievement }

class QueuedNotification {
  final String message;
  final SnackType type;
  final int duration;
  QueuedNotification(this.message, this.type, {this.duration = Constants.snackBarDuration});
}

class NotificationBus extends ChangeNotifier {
  NotificationBus._();
  static final NotificationBus instance = NotificationBus._();

  final List<QueuedNotification> _queue = [];
  bool _draining = false;

  void queue(String message, SnackType type, {int duration = Constants.snackBarDuration}) {
    _queue.add(QueuedNotification(message, type, duration: duration));
    notifyListeners();
  }

  void queueAchievement(String achievementName) {
    _queue.add(QueuedNotification('Achievement unlocked: $achievementName', SnackType.achievement));
    notifyListeners();
  }

  bool get hasNotifications => _queue.isNotEmpty;

  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    try {
      final overlay = navigatorKey.currentState?.overlay;
      if (overlay == null) return;
      while (_queue.isNotEmpty) {
        final n = _queue.removeAt(0);
        _show(overlay, n);
        await Future.delayed(Duration(milliseconds: n.duration + 100));
      }
    } finally {
      _draining = false;
    }
  }

  void _show(OverlayState overlay, QueuedNotification n) {
    Color bg;
    IconData? icon;
    switch (n.type) {
      case SnackType.success:
        bg = Colors.green.shade600;
        icon = Icons.check_circle_rounded;
        break;
      case SnackType.error:
        bg = Colors.red.shade400;
        icon = Icons.error_outline;
        break;
      case SnackType.achievement:
        bg = Colors.amber.shade800;
        icon = Icons.emoji_events;
        break;
      case SnackType.info:
        bg = Colors.blue.shade500;
        icon = Icons.info_outline;
        break;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => TopSnackBar(
        message: n.message,
        backgroundColor: bg,
        icon: icon,
        onDismissed: () => entry.remove(),
        duration: Duration(milliseconds: n.duration),
      ),
    );
    overlay.insert(entry);
  }
}

void notify(String message, SnackType type, {int duration = Constants.snackBarDuration}) =>
  NotificationBus.instance.queue(message, type, duration: duration);

void notifyAchievement(String name) =>
  NotificationBus.instance.queueAchievement(name);