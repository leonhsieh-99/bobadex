import 'package:bobadex/notification_bus.dart';
import 'package:flutter/material.dart';

class NotificationConsumer extends StatefulWidget {
  const NotificationConsumer({super.key});

  @override
  State<NotificationConsumer> createState() => _NotificationConsumerState();
}

class _NotificationConsumerState extends State<NotificationConsumer> {
  void _onChange() {
    if (!mounted || !NotificationBus.instance.hasNotifications) return;
    NotificationBus.instance.flush();
  }

  @override
  void initState() {
    super.initState();
    NotificationBus.instance.addListener(_onChange);
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
