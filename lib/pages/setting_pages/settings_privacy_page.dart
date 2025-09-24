import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPrivacyPage extends StatefulWidget{
  const SettingsPrivacyPage({super.key});

  @override
  State<SettingsPrivacyPage> createState() => _SettingsPrivacyPageState();
}

class _SettingsPrivacyPageState extends State<SettingsPrivacyPage> {
  late Box _prefs;
  bool _analyticsEnabled = true;
  // bool _crashEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _prefs = await Hive.openBox('prefs');
    setState(() {
      _analyticsEnabled = (_prefs.get('analytics_enabled') as bool?) ?? true;
      // _crashEnabled     = (_prefs.get('crash_enabled') as bool?) ?? true;
    });
  }

  Future<void> _setAnalytics(bool v) async {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(v);
    await _prefs.put('analytics_enabled', v);
    setState(() => _analyticsEnabled = v);
  }


  // Future<void> _setCrash(bool v) async {
  //   await _prefs.put('crash_enabled', v);
  //   setState(() => _crashEnabled = v);
  // }

  Future<void> _open(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        children: [
          SwitchListTile.adaptive(
            title: const Text('Share anonymous analytics'),
            subtitle: const Text('Help improve Bobadex (no ads, no cross-app tracking)'),
            value: _analyticsEnabled,
            onChanged: _setAnalytics,
          ),
          // const Divider(height: 0),
          // SwitchListTile.adaptive(
          //   title: const Text('Send crash reports'),
          //   subtitle: const Text('Diagnostics only, no sensitive content'),
          //   value: _crashEnabled,
          //   onChanged: _setCrash,
          // ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => _open('https://leonhsieh-99.github.io/bobadex-legal/privacy.html'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () => _open('https://leonhsieh-99.github.io/bobadex-legal/terms.html'),
          ),
        ],
      ),
    );
  }
}