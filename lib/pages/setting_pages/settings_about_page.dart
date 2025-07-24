import 'package:bobadex/helpers/show_snackbar.dart';
import 'package:bobadex/state/notification_queue.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// import 'package:url_launcher/url_launcher.dart';

class SettingsAboutPage extends StatelessWidget {
  const SettingsAboutPage ({super.key});

  // void _launchEmail() async {
  //   final Uri emailUri = Uri(
  //     scheme: 'mailto',
  //     path: 'leonchsieh@gmail.com',
  //     query: 'subject=Feedback%20for%20Bobadex%20App'
  //   );
  //   if (await canLaunchUrl(emailUri)) {
  //     launchUrl(emailUri);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Icon(Icons.coffee), // use logo later
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Bobadex',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Version 0.9 Beta',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          // About section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Bobadex is your personal boba shop and drink tracker.\n\n'
                '• Rate and journal your favorite boba drinks.\n'
                '• Discover new shops and share your reviews.\n'
                '• Beta version: some features may be in progress.\n',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // App limitations / disclaimer
          Card(
            elevation: 1,
            color: Colors.orange[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Limitations & Beta Notice:\n'
                '• Reporting is manual for now.\n'
                '• Currently the database only has California locations\n'
                '• Data may be wiped between updates.\n'
                '• Mascots are still experimental.\n'
                '• Please report bugs or feedback!',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange[900]),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Contact section
          Card(
            elevation: 0,
            color: theme.colorScheme.primary.withOpacity(0.07),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              child: Column(
                children: [
                  Text(
                    'Contact',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Questions, bugs, or suggestions?\nTap below to email me!',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.email),
                    label: const Text('Contact Me'),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: 'leonchsieh@gmail.com'));
                      context.read<NotificationQueue>().queue('Email copied to clipboard!', SnackType.info);
                    }
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}