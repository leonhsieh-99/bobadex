import 'package:bobadex/state/notification_queue.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationConsumer extends StatefulWidget {
  const NotificationConsumer({super.key});

  @override
  State<NotificationConsumer> createState() => _NotificationConsumerState();
}

class _NotificationConsumerState extends State<NotificationConsumer> {
  bool _isDraining = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _drainQueueIfNeeded();
    });
  }

  void _drainQueueIfNeeded() {
    if (!_isDraining && mounted) {
      final queue = Provider.of<NotificationQueue>(context, listen: false);
      if (queue.hasNotifications) {
        _isDraining = true;
        queue.drainQueue(context).then((_) {
          if (mounted) {
            setState(() {
              _isDraining = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<NotificationQueue>();
    
    // Only drain queue when notifications are added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _drainQueueIfNeeded();
    });
    
    return const SizedBox.shrink();
  }
}

