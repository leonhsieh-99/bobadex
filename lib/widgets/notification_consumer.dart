import 'package:bobadex/state/notification_queue.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationConsumer extends StatelessWidget {
  const NotificationConsumer({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<NotificationQueue>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationQueue>(context, listen: false).drainQueue(context);
    });
    return const SizedBox.shrink();
  }
}

