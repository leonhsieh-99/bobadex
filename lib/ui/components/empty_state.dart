import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.body,
    this.illustration,
    this.action,
  });

  final String title;
  final String? body;
  final Widget? illustration;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(BobaSpace.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              illustration ??
                  Icon(
                    Icons.local_drink_outlined,
                    size: 52,
                    color: tokens.inkFaint,
                  ),
              const SizedBox(height: BobaSpace.x4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (body != null) ...[
                const SizedBox(height: BobaSpace.x2),
                Text(
                  body!,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: tokens.inkMuted),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: BobaSpace.x5),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
