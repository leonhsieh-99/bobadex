import 'package:bobadex/helpers/show_snackbar.dart';
import 'package:flutter/material.dart';

class QueuedNotification {
  final String message;
  final SnackType type;

  QueuedNotification(this.message, this.type);
}

class NotificationQueue extends ChangeNotifier {
  final List<QueuedNotification> _queue = [];
  bool _draining = false;

  void queue(String message, SnackType type) {
    _queue.add(QueuedNotification(message, type));
    notifyListeners();
  }

  void queueAchievement(String achievementName) {
    _queue.add(QueuedNotification('Achievement unlocked: $achievementName', SnackType.achievement));
    notifyListeners();
  }

  List<QueuedNotification> consume() {
    final all = List<QueuedNotification>.from(_queue);
    _queue.clear();
    return all;
  }

  Future<void> drainQueue(BuildContext context) async {
    if (_draining) return;
    _draining = true;
    try {
      while (_queue.isNotEmpty) {
        final note = _queue.removeAt(0);
        if (context.mounted) showAppSnackBar(context, note.message, type: note.type);
        await Future.delayed(const Duration(milliseconds: 2000));
      }
    } finally {
      _draining = false;
    }
  }

  bool get hasNotifications => _queue.isNotEmpty;
}