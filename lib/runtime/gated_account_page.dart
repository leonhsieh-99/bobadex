import 'package:bobadex/auth/delete_account.dart';
import 'package:bobadex/auth/local_account_cleanup.dart';
import 'package:bobadex/helpers/export_data.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/about_page.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:flutter/material.dart';

/// Sign-out, support, export, and delete stay reachable while the app is gated.
class GatedAccountPage extends StatefulWidget {
  const GatedAccountPage({super.key});

  @override
  State<GatedAccountPage> createState() => _GatedAccountPageState();
}

class _GatedAccountPageState extends State<GatedAccountPage> {
  var _busy = false;

  Future<void> _delete() async {
    if (_busy) return;
    final host = context;
    final confirmed = await confirmAccountDeletion(host);
    if (!confirmed || !host.mounted) return;
    setState(() => _busy = true);
    final failure = await deleteConfirmedAccount(host);
    if (!context.mounted) return;
    setState(() => _busy = false);
    if (failure != null) notify(failure, SnackType.error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account and help')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.mail_outline_rounded),
            title: const Text('Support'),
            subtitle: const Text('Email, privacy, and terms'),
            onTap: _busy
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AboutPage(),
                      ),
                    );
                  },
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Export my data'),
            subtitle: const Text('Save a JSON file of your account'),
            onTap: _busy ? null : () => promptExportMyData(context),
          ),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: context.boba.danger),
            title: Text(
              'Sign out',
              style: TextStyle(color: context.boba.danger),
            ),
            onTap: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    await clearLocalAccount(context);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
          ),
          ListTile(
            enabled: !_busy,
            leading: Icon(Icons.delete_forever, color: context.boba.danger),
            title: Text(
              'Delete account',
              style: TextStyle(color: context.boba.danger),
            ),
            onTap: _delete,
          ),
        ],
      ),
    );
  }
}
