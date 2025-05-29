import 'package:flutter/material.dart';

class SettingsAccountPage extends StatefulWidget{
  const SettingsAccountPage({super.key});

  @override
  State<SettingsAccountPage> createState() => _SettingsAccountPageState();
}

class _SettingsAccountPageState extends State<SettingsAccountPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Account'),
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