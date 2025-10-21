import 'dart:math';

import 'package:bobadex/analytics_service.dart';
import 'package:bobadex/config/constants.dart';
import 'package:bobadex/models/account_stats.dart';
import 'package:bobadex/models/achievement.dart';
import 'package:bobadex/models/friendship.dart';
import 'package:bobadex/models/user.dart' as u;
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/brand_details_page.dart';
import 'package:bobadex/pages/home_page.dart';
import 'package:bobadex/pages/setting_pages/settings_account_page.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/state/user_stats_cache.dart';
import 'package:bobadex/widgets/badge_picker_dialog.dart';
import 'package:bobadex/widgets/icon_pic.dart';
import 'package:bobadex/widgets/profile_summary_card.dart';
import 'package:bobadex/widgets/report_widget.dart';
import 'package:bobadex/widgets/stat_box.dart';
import 'package:bobadex/widgets/social_widgets/user_feed_view.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountViewPage extends StatefulWidget {
  final String userId;
  final u.User? user; // user snapshot for fast ui

  const AccountViewPage ({
    super.key,
    required this.userId,
    this.user,
  });

  factory AccountViewPage.fromUser(u.User user) =>
    AccountViewPage(userId: user.id, user: user);

  @override
  State<AccountViewPage> createState() => _AccountViewPageState() ;
}

class _AccountViewPageState extends State<AccountViewPage> {
  bool _isLoading = false;
  AccountStats stats = AccountStats.emptyStats();
  List<Achievement> readOnlyBadges  = [];
  u.User? _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user; // paint snapshot if provided
    _fetchUser();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final supabase = Supabase.instance.client;
    setState(() => _isLoading = true);
    try {
      final stats = await context.read<UserStatsCache>().getStats(widget.userId);
      if (widget.userId != supabase.auth.currentUser!.id) {
        final response = await supabase
          .from('user_achievements')
          .select('achievement:achievement_id(*)')
          .eq('user_id', widget.userId)
          .eq('pinned', true);

        readOnlyBadges = (response as List)
            .map((row) => Achievement.fromJson(row['achievement']))
            .toList();
      }
      setState(() {
        this.stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUser() async {
    try {
      // skip if current user is self
      final selfId = context.read<UserState>().current.id;
      if (widget.userId == selfId) return;
      
      final row = await Supabase.instance.client
          .from('users')
          .select('id, username, display_name, profile_image_path, bio')
          .eq('id', widget.userId)
          .single();

      if (!mounted) return;
      setState(() {
        _user = u.User.fromJson(row);
      });
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
}

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    final brandState = context.read<BrandState>();
    final friendState = context.watch<FriendState>();
    final analytics = context.read<AnalyticsService>();

    final currentUser = userState.current;
    final isCurrentUser = currentUser.id == widget.userId;
    final user = isCurrentUser ? currentUser : (_user ?? u.User.empty());

    final brand = brandState.getBrand(stats.topShopSlug);
    final drinkName = stats.topDrinkName;
    final friendStatus = friendState.allFriendships.firstWhereOrNull((f) => f.requester.id == widget.userId || f.addressee.id == widget.userId);
    final achievementState = context.watch<AchievementsState>();
    final unlockedBadges = achievementState.achievements
        .where((a) => achievementState.progressMap[a.id]?.unlocked == true)
        .toList();
    final pinnedBadges = isCurrentUser 
      ? unlockedBadges.where((a) => achievementState.progressMap[a.id]?.pinned == true).toList()
      : readOnlyBadges;

    String getFriendButtonText(Friendship? friendStatus, String currentUserId, String targetUserId) {
      if (friendStatus == null) {
        return 'Add friend';
      }
      if (friendStatus.status == 'pending') {
        if (friendStatus.requester.id == targetUserId) {
          return 'Accept friend';
        }
        if (friendStatus.addressee.id == targetUserId) {
          return 'Pending';
        }
      }
      if (friendStatus.status == 'accepted') {
        return 'Friends';
      }
      return '';
    }

    bool isFriendButtonEnabled(Friendship? friendStatus, String currentUserId, String targetUserId) {
      if (_user == null) return false;
      if (friendStatus == null) {
        return true;
      }
      // Only enable accept if current user is the addressee
      if (friendStatus.status == 'pending' && friendStatus.requester.id == targetUserId) {
        return true;
      }
      // Otherwise, button should be disabled
      return false;
    }

    final themeColor = Constants.getThemeColor(userState.current.themeSlug);

    final friendBtn = (!isCurrentUser)
      ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: TextButton.icon(
            icon: const Icon(Icons.person_add_rounded, size: 18, color: Colors.white),
            label: Text(getFriendButtonText(friendStatus, currentUser.id, widget.userId)),
            onPressed: isFriendButtonEnabled(friendStatus, currentUser.id, widget.userId)
              ? () async {
                  if (friendStatus == null) {
                    await friendState.addUser(user);
                  } else if (friendStatus.status == 'pending' && friendStatus.requester.id == widget.userId) {
                    await friendState.acceptUser(widget.userId);
                    await analytics.friendRequestAccepted();
                  }
                }
              : null,
            style: ButtonStyle(
              backgroundColor:  WidgetStatePropertyAll(friendStatus?.status == 'accepted' ? themeColor.shade100 : themeColor.shade400),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14, vertical: 6)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
            ),
          ),
        )
      : null;

    final viewBtn = (!isCurrentUser)
      ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: TextButton.icon(
            icon: const Icon(Icons.menu_book_rounded, size: 18, color: Colors.white),
            label: const Text('View Bobadex'),
            onPressed: (_user != null)
              ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HomePage(userId: _user!.id)))
              : null,
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(themeColor.shade400),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14, vertical: 6)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
            ),
          ),
        )
      : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: TextButton.icon(
            icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
            label: const Text('Edit Profile'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsAccountPage())),
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(themeColor.shade400),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14, vertical: 6)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
            ),
          ),
        );

    final favTile = _isLoading
      ? const ShopTileSkeleton()
      : (brand != null)
          ? ListTile(
              leading: IconPic(path: brand.iconPath, size: 48),
              title: Text(brand.display, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(drinkName, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BrandDetailsPage(brand: brand))),
            )
          : Center(child: Text(isCurrentUser ? 'No shops yet, add in home page' : 'User has no shops yet', style: Constants.emptyListTextStyle));

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (!isCurrentUser)
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'remove':
                    try {
                      await context.read<FriendState>().removeFriend(widget.userId);
                      notify('Removed friend', SnackType.success);
                    } catch (_) {
                      notify('Could not remove friend. Try again.', SnackType.error);
                    }
                    break;

                  case 'cancel_request':
                    try {
                      await context.read<FriendState>().removeFriend(widget.userId);
                      notify('Friend request canceled', SnackType.success);
                    } catch (_) {
                      notify('Could not cancel request. Try again.', SnackType.error);
                    }
                    break;

                  case 'reject_request':
                    try {
                      await context.read<FriendState>().rejectUser(widget.userId);
                      notify('Friend request rejected', SnackType.success);
                    } catch (_) {
                      notify('Could not reject request. Try again.', SnackType.error);
                    }
                    break;

                  case 'report':
                    showDialog(
                      context: context,
                      builder: (_) => ReportDialog(
                        contentType: 'user',
                        contentId: widget.userId,
                        reportedUserId: widget.userId,
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (_) {
                final items = <PopupMenuEntry<String>>[];

                if (friendStatus?.status == 'accepted') {
                  items.add(const PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove friend'),
                  ));
                } else if (friendStatus?.status == 'pending') {
                  if (friendStatus!.requester.id == currentUser.id) {
                    items.add(const PopupMenuItem(
                      value: 'cancel_request',
                      child: Text('Cancel friend request'),
                    ));
                  } else if (friendStatus.addressee.id == currentUser.id) {
                    items.add(const PopupMenuItem(
                      value: 'reject_request',
                      child: Text('Reject friend request'),
                    ));
                  }
                }

                items.add(const PopupMenuItem(
                  value: 'report',
                  child: Text('Report'),
                ));
                return items;
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ProfileSummaryCard(
                displayName: user.displayName,
                username: user.username,
                bio: user.bio,
                profileImagePath: user.profileImagePath,
                leadingAction: friendBtn,
                trailingAction: viewBtn,
                favoriteShopTile: favTile,
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _isLoading
                  ? [StatCardSkeleton(), StatCardSkeleton()]
                  : [
                      StatCard(label: 'Shops',  value: stats.shopCount,  emoji: '⭐'),
                      StatCard(label: 'Drinks', value: stats.drinkCount, emoji: '🧋'),
                    ],
              ),
              SizedBox(height: 16),
              _BadgesSection(
                badges: pinnedBadges,
                isOwner: isCurrentUser,
                onTapManage: isCurrentUser ? () { 
                  showDialog(
                    context: context,
                    builder: (context) =>
                      BadgePickerDialog(
                        badges: unlockedBadges,
                        pinnedBadges: pinnedBadges,
                                                onSave: (selected) async {
                          try {
                            for (final a in unlockedBadges) {
                              final shouldPin = selected.contains(a.id);
                              if (achievementState.progressMap[a.id]?.pinned != shouldPin) {
                                await achievementState.setPinned(a.id);
                              }
                            }
                            if(context.mounted) Navigator.of(context).pop();
                          } catch (e) {
                            if (context.mounted) { 
                              notify('Error pinning badges', SnackType.error);
                            }
                          }
                        },
                      )
                  );
                } : null,
                isLoading: _isLoading,
              ),
              const Divider(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              UserFeedView(
                userId: widget.userId,
                isOwner: isCurrentUser,
                pageSize: 10,
              ),
            ],
          ),
        )
      )
    );
  }
}

class ShopTileSkeleton extends StatelessWidget {
  const ShopTileSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
      ),
      title: Container(
        width: 80,
        height: 12,
        color: Colors.grey[300],
      ),
      subtitle: Container(
        width: 60,
        height: 10,
        color: Colors.grey[200],
        margin: EdgeInsets.only(top: 4),
      ),
    );
  }
}

class BadgeRowSkeleton extends StatelessWidget {
  const BadgeRowSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3, // Show 3 fake badges
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CircleAvatar(
            backgroundColor: Colors.grey[300],
            radius: 22,
          ),
        ),
      ),
    );
  }
}

class _BadgesSection extends StatelessWidget {
  const _BadgesSection({
    required this.badges,
    required this.isOwner,
    required this.onTapManage,
    required this.isLoading,
  });

  final List<Achievement> badges;
  final bool isOwner;
  final VoidCallback? onTapManage;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header row
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, size: 18),
              const SizedBox(width: 8),
              Text('Badges', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface)),
              const Spacer(),
              if (isOwner)
                TextButton.icon(
                  icon: const Icon(Icons.push_pin, size: 16, color: Colors.black),
                  label: const Text('Pin', style: TextStyle(color: Colors.black)),
                  onPressed: onTapManage,
                  style: ButtonStyle(
                    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                    backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
                  ),
                )
            ],
          ),

          // content
          if (isLoading)
            const _BadgeRowSkeleton()
          else if (badges.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                isOwner ? 'No badges yet, tap Pin to choose.' : 'No badges yet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.6)),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cs = Theme.of(context).colorScheme;
                final count = badges.length;
                if (count == 0) return const SizedBox.shrink();

                const gap = 10.0;
                final totalGaps = gap * (count - 1);
                final maxW = (constraints.maxWidth - totalGaps) / 3;
                final slotW = min((constraints.maxWidth - totalGaps) / count, maxW);

                final avatarR = slotW * 0.38;                     // radius
                final labelFS = (slotW * 0.1).clamp(8.0, 11.0);  // font size
                final labelHPad = (slotW * 0.14).clamp(6.0, 10.0);
                final labelVPad = (slotW * 0.07).clamp(3.0, 6.0);

                final children = <Widget>[];
                for (int i = 0; i < count; i++) {
                  final a = badges[i];
                  final img = (a.iconPath != null && a.iconPath!.isNotEmpty)
                      ? AssetImage(a.iconPath!)
                      : const AssetImage('lib/assets/badges/default_badge.png');

                  children.add(
                    SizedBox(
                      width: slotW,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: avatarR,
                            backgroundColor: Constants.badgeBgColor,
                            backgroundImage: img,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: labelHPad, vertical: labelVPad),
                            decoration: BoxDecoration(
                              color: cs.surface.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
                            ),
                            child: Text(
                              a.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: labelFS, fontWeight: FontWeight.w600, height: 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                  if (i != count - 1) {
                    children.add(const SizedBox(width: gap));
                  }
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: children,
                );
              },
            )
        ],
      ),
    );
  }
}

class _BadgeRowSkeleton extends StatelessWidget {
  const _BadgeRowSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 16, runSpacing: 8,
      children: List.generate(3, (_) => CircleAvatar(radius: 22, backgroundColor: cs.surfaceVariant)),
    );
  }
}