import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/user_state.dart';
import 'package:bobadex/config/constants.dart';

class SettingsThemePage extends StatefulWidget{
  const SettingsThemePage({super.key});

  @override
  State<SettingsThemePage> createState() => _SettingsThemePageState();
}

class _SettingsThemePageState extends State<SettingsThemePage> {
  final themeMap = Constants.themeMap;
  late final String originalTheme;

  @override
  void initState() {
    super.initState();
    originalTheme = context.read<UserState>().current.themeSlug;
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.read<UserState>();
    return PopScope(
      onPopInvokedWithResult: (didPop, result) => originalTheme != userState.current.themeSlug ? userState.saveTheme() : null,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Theme'),
        ),
        body: Column(
          children: [
            Text('Color'),
            Expanded( 
              child: ListView(
                children: themeMap.entries.map((entry) {
                  final slug = entry.key;
                  final color = entry.value;

                  return ListTile(
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: userState.current.themeSlug == slug ? Colors.black : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    title: Text(slug),
                    trailing: userState.current.themeSlug == slug ? const Icon(Icons.check) : null,
                    onTap: () {
                      setState(() {
                        userState.setTheme(slug);
                      });
                    }
                  );
                }).toList(),
              )
            ),
          ],
        ),
      ),
    );
  }
}