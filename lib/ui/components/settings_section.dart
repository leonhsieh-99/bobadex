import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BobaSpace.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BobaSpace.x4,
              BobaSpace.x3,
              BobaSpace.x4,
              BobaSpace.x2,
            ),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.boba.inkMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
