import 'package:flutter/material.dart';
import '../../models/user_cache.dart';
class SettingsThemePage extends StatefulWidget{
  const SettingsThemePage({super.key});

  @override
  State<SettingsThemePage> createState() => _SettingsThemePageState();
}

class _SettingsThemePageState extends State<SettingsThemePage> {
  final Map<String, MaterialColor> themeMap = UserCache.themeMap;
  String? selectedSlug = UserCache.themeSlug;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Theme'),
      ),
      body: Column(
        children: [
          Text('Color'),
          Expanded( 
            child:ListView(
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
                        color: selectedSlug == slug ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  title: Text(slug),
                  trailing: selectedSlug == slug ? const Icon(Icons.check) : null,
                  onTap: () {
                    setState(() {
                      selectedSlug = slug;
                      UserCache.themeSlug = slug;
                    });
                  }
                );
              }).toList(),
            )
          ),
        ],
      ),
    );
  }
}