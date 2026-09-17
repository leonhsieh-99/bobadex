import 'package:bobadex/config/ai_disclosure.dart';
import 'package:bobadex/pages/setting_pages/settings_ai_data_page.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class SettingsLayoutPage extends StatefulWidget {
  const SettingsLayoutPage({super.key});

  @override
  State<SettingsLayoutPage> createState() => _SettingsLayoutPageState();
}

class _SettingsLayoutPageState extends State<SettingsLayoutPage> {
  late final int originalColumns;
  late final bool originalIcons;
  late final bool originalMascots;

  @override
  void initState() {
    super.initState();
    final current = context.read<UserState>().current;
    originalColumns = current.gridColumns;
    originalIcons = current.useIcons;
    originalMascots = current.useMascots;
  }

  bool _layoutChanged(UserState userState) {
    final current = userState.current;
    return originalColumns != current.gridColumns ||
        originalIcons != current.useIcons ||
        originalMascots != current.useMascots;
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    return PopScope(
      onPopInvokedWithResult: (didPop, result) =>
          _layoutChanged(userState) ? userState.saveLayout() : null,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Layout'),
        ),
        body: ListView(
          children: [
            ListTile(
              title: const Text('Compact Layout'),
              subtitle: const Text('3 shops per column'),
              trailing: Switch(
                value: userState.current.gridColumns == 3,
                onChanged: (val) {
                  userState.setGridLayout(val ? 3 : 2);
                },
              ),
            ),
            ListTile(
              title: const Text('Use Banner Photos'),
              subtitle: const Text('Home page cards use your banner photo instead of brand visuals'),
              trailing: Switch(
                value: !userState.current.useIcons,
                onChanged: (val) {
                  userState.toggleUseIcons();
                },
              ),
            ),
            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Brand visuals',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userState.current.useMascots
                        ? 'Illustrated mascots for each brand'
                        : 'Lettering based on each brand name',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<bool>(
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
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsAiDataPage()),
                    ),
                    child: const Text(AiDisclosure.settingsTitle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
