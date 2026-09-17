import 'package:bobadex/config/ai_disclosure.dart';
import 'package:bobadex/pages/setting_pages/settings_layout_page.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsAiDataPage extends StatelessWidget {
  const SettingsAiDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AiDisclosure.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            AiDisclosure.body,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 24),
          Text(
            'Brand visuals',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Mascots')),
              ButtonSegment(value: false, label: Text('Minimal')),
            ],
            selected: {userState.current.useMascots},
            onSelectionChanged: (selected) {
              userState.setUseMascots(selected.first);
              userState.saveLayout();
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Mascots are the default. Minimal uses lettering from each brand name.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Layout'),
            subtitle: const Text('Grid density and banner photos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsLayoutPage()),
            ),
          ),
        ],
      ),
    );
  }
}
