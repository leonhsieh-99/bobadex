import 'package:bobadex/config/constants.dart';
import 'package:bobadex/navigation.dart';
import 'package:bobadex/widgets/top_snack_bar.dart';
import 'package:flutter/material.dart';

export 'package:bobadex/widgets/top_snack_bar.dart' show SnackType;

class QueuedNotification {
  final String message;
  final SnackType type;
  final int duration;
  QueuedNotification(
    this.message,
    this.type, {
    this.duration = Constants.snackBarDuration,
  });
}

class NotificationBus extends ChangeNotifier {
  NotificationBus._();
  static final NotificationBus instance = NotificationBus._();

  QueuedNotification? _latest;
  OverlayEntry? _entry;
  int _epoch = 0;
  bool _scheduled = false;
  int _retries = 0;

  void queue(
    String message,
    SnackType type, {
    int duration = Constants.snackBarDuration,
  }) {
    _latest = QueuedNotification(message, type, duration: duration);
    notifyListeners();
    _schedule();
  }

  void queueAchievement(String achievementName) {
    queue('Achievement unlocked: $achievementName', SnackType.achievement);
  }

  bool get hasNotifications => _latest != null;

  void flush() => _schedule();

  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      _present();
    });
  }

  void _present() {
    final next = _latest;
    if (next == null) return;
    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay == null) {
      if (_retries < 20) {
        _retries++;
        _schedule();
      }
      return;
    }
    _retries = 0;
    _latest = null;
    final epoch = ++_epoch;
    _entry?.remove();
    _entry = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => TopSnackBar(
        key: ValueKey(epoch),
        message: next.message,
        type: next.type,
        duration: Duration(milliseconds: next.duration),
        onDismissed: () {
          if (_epoch != epoch || _entry != entry) return;
          _entry = null;
          entry.remove();
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }
}

void notify(
  String message,
  SnackType type, {
  int duration = Constants.snackBarDuration,
}) => NotificationBus.instance.queue(message, type, duration: duration);

void notifyAchievement(String name) =>
    NotificationBus.instance.queueAchievement(name);
