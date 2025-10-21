import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:flutter/material.dart';

class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({
    super.key,
    required this.displayName,
    required this.username,
    this.bio,
    this.profileImagePath,
    this.leadingAction,
    this.trailingAction,
    this.favoriteShopTile,
  });

  final String displayName;
  final String username;
  final String? bio;
  final String? profileImagePath;
  final Widget? leadingAction;
  final Widget? trailingAction;
  final Widget? favoriteShopTile;

  @override
  Widget build(BuildContext context) {
    const double headerH = 100;
    const double avatarR = 70;

    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Gradient header cap
          Container(
            height: headerH,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [cs.primary.withOpacity(0.18), cs.primary.withOpacity(0.06)],
              ),
            ),
          ),

          Positioned(
            top: headerH - avatarR,
            left: 0, right: 0,
            child: CircleAvatar(
              radius: avatarR,
              backgroundColor: Colors.white,
              child: ThumbPic(path: profileImagePath, size: avatarR * 2 - 10)
            ),
          ),

          // Content below avatar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, headerH + avatarR + 12, 16, 16),
            child: Column(
              children: [
                Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                Text('@$username', style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
                const SizedBox(height: 8),
                Text(
                  (bio == null || bio!.trim().isEmpty) ? 'No bio set' : bio!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: (bio == null || bio!.trim().isEmpty) ? cs.onSurface.withOpacity(0.4) : null,
                  ),
                ),
                const SizedBox(height: 12),

                // cute chip actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (leadingAction != null) leadingAction!,
                    if (leadingAction != null && trailingAction != null) const SizedBox(width: 10),
                    if (trailingAction != null) trailingAction!,
                  ],
                ),
                if (favoriteShopTile != null) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Material(
                      color: cs.surfaceVariant.withOpacity(0.3),
                      child: SizedBox(height: 64, child: favoriteShopTile),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
