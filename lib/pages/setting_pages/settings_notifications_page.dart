import 'package:flutter/material.dart';

class SettingsNotificationsPage extends StatefulWidget{
  const SettingsNotificationsPage({super.key});

  @override
  State<SettingsNotificationsPage> createState() => _SettingsNotificationsPageState();
}

class _SettingsNotificationsPageState extends State<SettingsNotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Notifications'),
      ),
      body: Column(
        children: [
          ListTile(
          )
        ],
      ),
    );
  }
}