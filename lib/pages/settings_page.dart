import 'package:bobadex/config/ai_disclosure.dart';
import 'package:bobadex/helpers/export_data.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/setting_pages/settings_account_page.dart';
import 'package:bobadex/push/push_registration.dart';
import 'package:bobadex/pages/setting_pages/settings_ai_data_page.dart';
import 'package:bobadex/pages/setting_pages/settings_layout_page.dart';
import 'package:bobadex/pages/setting_pages/settings_privacy_page.dart';
import 'package:bobadex/pages/setting_pages/settings_theme_page.dart';
import 'package:bobadex/ui/components/boba_nav_bar.dart';
import 'package:bobadex/ui/components/settings_section.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/widgets/confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.only(bottom: BobaNavBar.clearance(context)),
        children: [
          SettingsSection(
            title: 'Appearance',
            children: [
              ListTile(
                leading: const Icon(Icons.palette_rounded),
                title: const Text('Theme'),
                subtitle: const Text('Color and paper of the ledger'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsThemePage()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.grid_view_rounded),
                title: const Text('Layout'),
                subtitle: const Text('Grid, photos, and brand visuals'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsLayoutPage()),
                ),
              ),
            ],
          ),
          SettingsSection(
            title: 'Account',
            children: [
              ListTile(
                leading: const Icon(Icons.person_rounded),
                title: const Text('Your account'),
                subtitle: const Text('Name, username, photo, and email'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsAccountPage(),
                  ),
                ),
              ),
            ],
          ),
          SettingsSection(
            title: 'Privacy & data',
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline_rounded),
                title: const Text('Privacy'),
                subtitle: const Text('Who can find you and see your dex'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsPrivacyPage(),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome_rounded),
                title: Text(AiDisclosure.settingsTitle),
                subtitle: const Text('How Bobadex uses automated systems'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsAiDataPage()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('Export my data'),
                subtitle: const Text('Copy a JSON export to clipboard'),
                onTap: () async {
                  final res = await exportMyData(context);
                  if (res == true) notify('Export copied!', SnackType.success);
                },
              ),
            ],
          ),
          SettingsSection(
            title: 'Session',
            children: [
              ListTile(
                leading: Icon(Icons.logout_rounded, color: context.boba.danger),
                title: Text(
                  'Sign out',
                  style: TextStyle(color: context.boba.danger),
                ),
                onTap: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'Sign Out',
                    message: 'Are you sure you want to sign out?',
                    confirmText: 'Sign Out',
                    confirmColor: context.boba.accent,
                  );
                  if (confirmed) {
                    await PushRegistration.removeCurrent();
                    await Supabase.instance.client.auth.signOut();
                  }
                },
              ),
            ],
          ),
          SettingsSection(
            title: 'About',
            children: [
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snap) {
                  final info = snap.data;
                  final label = info == null
                      ? '…'
                      : '${info.version} (${info.buildNumber})';
                  return ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('Version'),
                    subtitle: Text(label),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
