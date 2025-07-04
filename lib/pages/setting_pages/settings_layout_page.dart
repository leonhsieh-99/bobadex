import 'package:bobadex/state/user_state.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class SettingsLayoutPage extends StatefulWidget {
  const SettingsLayoutPage({super.key});

  @override
  State<SettingsLayoutPage> createState() => _SettingsLayoutPageState();
}

class _SettingsLayoutPageState extends State<SettingsLayoutPage> {
  @override
  Widget build(BuildContext context) {
    final userState = context.read<UserState>();
    return PopScope(
      onPopInvokedWithResult: (didPop, result) => userState.saveLayout(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Layout'),
        ),
        body: Column(
          children: [
            ListTile(
              title: const Text('Compact Layout'),
              subtitle: const Text('3 shops per column'),
              trailing: Switch(
                value: userState.user.gridColumns == 3,
                onChanged: (val) {
                  setState(() => userState.setGridLayout(val ? 3 : 2));
                })
            ),
            ListTile(
              title: const Text('Use Banner Photos'),
              subtitle: const Text('Home page icons will use your banner photo instead of the icons'),
              trailing: Switch(
                value: !userState.user.useIcons,
                onChanged: (val) {
                  setState(() => userState.setUseIcon());
                })
            )
          ],
        ),
      ),
    );
  }
}