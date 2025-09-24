import 'package:bobadex/notification_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage ({super.key});

  static const _privacyUrl = 'https://leonhsieh-99.github.io/bobadex-legal/privacy.html';
  static const _termsUrl   = 'https://leonhsieh-99.github.io/bobadex-legal/terms.html';
  static const _supportEmail = 'leonchsieh@gmail.com';


  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) notify('Could not open link', SnackType.error);
  }

  Future<void> _emailSupport(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: Uri(queryParameters: {
        'subject': 'Bobadex feedback v${info.version} (${info.buildNumber})',
      }).query,
    );
    if (!await launchUrl(uri)) {
      // Fallback: copy to clipboard
      Clipboard.setData(const ClipboardData(text: _supportEmail));
      notify('Email copied to clipboard!', SnackType.info);
    }
  }

  Future<void> _rateApp() async {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '-';
        final build = snapshot.data?.buildNumber ?? '';

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
                  child: SvgPicture.asset(
                    'lib/assets/logo.svg',
                    width: 96,
                    height: 96,
                  ),
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
                child: Text('Version $version ($build)',
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
                    'Bobadex is your personal boba shop and drink tracker. '
                    'This is truthfully like a more niche and hopefully cuter version of beli.'
                    ' I made this mostly for fun and because I drink an unhealthy amount'
                    ' of milk tea. '
                    'If anyone has any suggestions or feedback you can get my email in the contacts below. '
                    'Anyways I don\'t have much to say. Hope everyone has a '
                    'lovely time using this app\n\n- Leon~',
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
              // Contact
              Card(
                elevation: 0,
                color: theme.colorScheme.primary.withOpacity(0.07),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  child: Column(
                    children: [
                      Text('Contact',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Questions, bugs, or suggestions?\nTap below to email me!',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.email),
                        label: const Text('Contact Me'),
                        onPressed: () => _emailSupport(context),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.star_rate_rounded),
                        label: const Text('Rate Bobadex'),
                        onPressed: _rateApp,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Open-source licenses'),
                        onPressed: () => showLicensePage(
                          context: context,
                          applicationName: 'Bobadex',
                          applicationVersion: 'v$version ($build)',
                        ),
                      ),
                    ],
                  ),
                )
              ),
              const SizedBox(height: 16),
              // Legal links
              Card(
                elevation: 0,
                color: theme.colorScheme.primary.withOpacity(0.07),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  child: Column(
                    children: [
                      Text('Legal',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _openUrl(_privacyUrl),
                              child: Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12
                                )
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _openUrl(_termsUrl),
                              child: Text(
                                'Terms of Service',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12
                                )
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: InkWell(
                  onTap: () => _openUrl('https://www.openstreetmap.org/copyright'),
                  child: Text(
                    '© OpenStreetMap contributors (ODbL)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700], decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ]
          ),
        );
      }
    );
  }
}