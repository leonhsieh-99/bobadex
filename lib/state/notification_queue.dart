import 'package:bobadex/helpers/show_snackbar.dart';
import 'package:flutter/material.dart';

class QueuedNotification {
  final String message;
  final SnackType type;
  final int duration;

  QueuedNotification(this.message, this.type, {this.duration = 1900});
}

class NotificationQueue extends ChangeNotifier {
  final List<QueuedNotification> _queue = [];
  bool _draining = false;

  void queue(String message, SnackType type, {int duration = 1900}) {
    _queue.add(QueuedNotification(message, type, duration: duration));
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
        if (context.mounted) showAppSnackBar(context, note.message, type: note.type, duration: note.duration);
        await Future.delayed(Duration(milliseconds: note.duration + 100));
      }
    } finally {
      _draining = false;
    }
  }

  bool get hasNotifications => _queue.isNotEmpty;
}