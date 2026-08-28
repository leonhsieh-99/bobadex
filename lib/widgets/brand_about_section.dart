import 'package:bobadex/models/brand_profile.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BrandAboutSection extends StatelessWidget {
  final BrandProfile profile;
  final MaterialColor themeColor;

  const BrandAboutSection({
    super.key,
    required this.profile,
    required this.themeColor,
  });

  Future<void> _openWebsite(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok) notify('Could not open link', SnackType.error);
  }

  @override
  Widget build(BuildContext context) {
    if (!profile.hasContent) return const SizedBox.shrink();

    final chipColor = themeColor.shade100;
    final chipShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          if (profile.hasAbout) ...[
            const SizedBox(height: 8),
            Text(
              profile.publicSummary!,
              style: const TextStyle(fontSize: 15, height: 1.35),
            ),
          ],
          if (profile.hasChips) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (profile.foundedYear != null)
                  _infoChip('Est. ${profile.foundedYear}', chipColor, chipShape),
                if (profile.locationLabel != null)
                  _infoChip(profile.locationLabel!, chipColor, chipShape),
                if (profile.website != null)
                  ActionChip(
                    label: const Text('Website', style: TextStyle(fontSize: 13)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: chipColor,
                    shape: chipShape,
                    side: BorderSide.none,
                    onPressed: () => _openWebsite(profile.website!),
                  ),
              ],
            ),
          ],
          if (profile.knownFor.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Known for', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in profile.knownFor)
                  _infoChip(item, chipColor, chipShape),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(String label, Color background, OutlinedBorder shape) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      visualDensity: VisualDensity.compact,
      backgroundColor: background,
      shape: shape,
      side: BorderSide.none,
    );
  }
}

class BrandAboutSkeleton extends StatelessWidget {
  const BrandAboutSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 14,
            width: 220,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}
