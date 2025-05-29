import 'package:bobadex/pages/setting_pages/settings_account_page.dart';
import 'package:bobadex/pages/setting_pages/settings_notifications_page.dart';
import 'package:bobadex/pages/setting_pages/settings_theme_page.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Column(
        children: [
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Your account'),
            subtitle: Text('password and user management'),
            trailing: Icon(Icons.chevron_right),
            onTap:() => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingsAccountPage())
            ),
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            subtitle: Text('Manage your notifications'),
            trailing: Icon(Icons.chevron_right),
            onTap:() => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingsNotificationsPage())
            ),
          ),
          ListTile(
            leading: Icon(Icons.color_lens),
            title: Text('Theme'),
            subtitle: Text('Manage the way your display looks'),
            trailing: Icon(Icons.chevron_right),
            onTap:() => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingsThemePage())
            ),
          ),
        ],
      ),
    );
  }
}