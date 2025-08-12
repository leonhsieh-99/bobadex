import 'package:bobadex/notification_bus.dart';
import 'package:flutter/material.dart';

class NotificationConsumer extends StatefulWidget {
  const NotificationConsumer({super.key});

  @override
  State<NotificationConsumer> createState() => _NotificationConsumerState();
}

class _NotificationConsumerState extends State<NotificationConsumer> {
  bool _draining = false;

  void _onChange() {
    if (!mounted || _draining || !NotificationBus.instance.hasNotifications) return;
    _drain();
  }

  Future<void> _drain() async {
    _draining = true;
    try {
      await NotificationBus.instance.drain();
    } finally {
      _draining = false;
      if (mounted && NotificationBus.instance.hasNotifications) _drain();
    }
  }

  @override
    void initState() {
      super.initState();
      NotificationBus.instance.addListener(_onChange);
      // drain anything queued early
      WidgetsBinding.instance.addPostFrameCallback((_) => _onChange());
    }

  @override
  void dispose() {
    NotificationBus.instance.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

