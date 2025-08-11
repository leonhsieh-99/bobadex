import 'package:bobadex/state/notification_queue.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationConsumer extends StatefulWidget {
  const NotificationConsumer({super.key});

  @override
  State<NotificationConsumer> createState() => _NotificationConsumerState();
}

class _NotificationConsumerState extends State<NotificationConsumer> {
  NotificationQueue? _queue;
  late final VoidCallback _listener;
  bool _draining = false;

  @override
  void initState() {
    super.initState();
    _listener = _onQueueChanged;
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newQueue = context.read<NotificationQueue>();
    if (_queue != newQueue) {
      _queue?.removeListener(_listener);
      _queue = newQueue..addListener(_listener);
    }

    _onQueueChanged();
  }

  void _onQueueChanged() {
    if (!mounted || _draining) return;
    if (!(_queue?.hasNotifications ?? false)) return;
    _drain();
  }

  Future<void> _drain() async {
    if (!mounted) return;
    _draining = true;
    try {
      await _queue?.drainQueue();
    } finally {
      _draining = false;
      if (mounted && (_queue?.hasNotifications ?? false)) {
        _drain();
      }
    }
  }

  @override
  void dispose() {
    _queue?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

