import 'package:bobadex/analytics_service.dart';
import 'package:bobadex/models/account_stats.dart';
import 'package:bobadex/models/achievement.dart';
import 'package:bobadex/models/friendship.dart';
import 'package:bobadex/models/user.dart' as u;
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/brand_details_page.dart';
import 'package:bobadex/pages/about_page.dart';
import 'package:bobadex/pages/achievements_page.dart';
import 'package:bobadex/pages/home_page.dart';
import 'package:bobadex/pages/settings_page.dart';
import 'package:bobadex/pages/setting_pages/settings_account_page.dart';
import 'package:bobadex/pages/user_activity_page.dart';
import 'package:bobadex/ui/components/boba_nav_bar.dart';
import 'package:bobadex/ui/components/collector_card.dart';
import 'package:bobadex/ui/components/leaderboard_preview.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/state/user_stats_cache.dart';
import 'package:bobadex/widgets/brand_mark.dart';
import 'package:bobadex/widgets/report_dialog.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountViewPage extends StatefulWidget {
  final String userId;
  final u.User? user; // user snapshot for fast ui
  final bool inShell;

  const AccountViewPage({
    super.key,
    required this.userId,
    this.user,
    this.inShell = false,
  });

  factory AccountViewPage.fromUser(u.User user) =>
      AccountViewPage(userId: user.id, user: user);

  @override
  State<AccountViewPage> createState() => _AccountViewPageState();
}

class _AccountViewPageState extends State<AccountViewPage> {
  bool _isLoading = false;
  AccountStats stats = AccountStats.emptyStats();
  List<Achievement> readOnlyBadges = [];
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
      final stats = await context.read<UserStatsCache>().getStats(
        widget.userId,
      );
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
          .select(
            'id, username, display_name, profile_image_path, bio, created_at',
          )
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
    final currentUser = context.select<UserState, u.User>((s) => s.current);
    final brandState = context.read<BrandState>();
    final friendState = context.watch<FriendState>();
    final analytics = context.read<AnalyticsService>();

    final isCurrentUser = currentUser.id == widget.userId;
    final user = isCurrentUser ? currentUser : (_user ?? u.User.empty());

    final brand = brandState.getBrand(stats.topShopSlug);
    final drinkName = stats.topDrinkName;
    final friendStatus = friendState.allFriendships.firstWhereOrNull(
      (f) => f.requester.id == widget.userId || f.addressee.id == widget.userId,
    );
    final achievementState = context.watch<AchievementsState>();
    final unlockedBadges = achievementState.achievements
        .where((a) => achievementState.progressMap[a.id]?.unlocked == true)
        .toList();
    final pinnedBadges = isCurrentUser
        ? unlockedBadges
              .where((a) => achievementState.progressMap[a.id]?.pinned == true)
              .toList()
        : readOnlyBadges;

    String getFriendButtonText(
      Friendship? friendStatus,
      String currentUserId,
      String targetUserId,
    ) {
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

    bool isFriendButtonEnabled(
      Friendship? friendStatus,
      String currentUserId,
      String targetUserId,
    ) {
      if (_user == null) return false;
      if (friendStatus == null) {
        return true;
      }
      // Only enable accept if current user is the addressee
      if (friendStatus.status == 'pending' &&
          friendStatus.requester.id == targetUserId) {
        return true;
      }
      // Otherwise, button should be disabled
      return false;
    }

    final friendBtn = (!isCurrentUser)
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: TextButton.icon(
              icon: Icon(
                Icons.person_add_rounded,
                size: 18,
                color: context.boba.onAccent,
              ),
              label: Text(
                getFriendButtonText(
                  friendStatus,
                  currentUser.id,
                  widget.userId,
                ),
              ),
              onPressed:
                  isFriendButtonEnabled(
                    friendStatus,
                    currentUser.id,
                    widget.userId,
                  )
                  ? () async {
                      if (friendStatus == null) {
                        await friendState.addUser(user);
                      } else if (friendStatus.status == 'pending' &&
                          friendStatus.requester.id == widget.userId) {
                        await friendState.acceptUser(widget.userId);
                        await analytics.friendRequestAccepted();
                      }
                    }
                  : null,
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  friendStatus?.status == 'accepted'
                      ? context.boba.accentSoft
                      : context.boba.accent,
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          )
        : null;

    final viewBtn = (!isCurrentUser)
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: TextButton.icon(
              icon: const Icon(Icons.menu_book_rounded, size: 18),
              label: const Text('View Bobadex'),
              onPressed: (_user != null)
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HomePage(userId: _user!.id),
                      ),
                    )
                  : null,
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(context.boba.accent),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.disabled)
                      ? context.boba.inkFaint
                      : context.boba.onAccent;
                }),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          )
        : null;

    final favTile = _isLoading
        ? const ShopTileSkeleton()
        : (brand != null)
        ? ListTile(
            leading: BrandMark(
              name: brand.display,
              slug: brand.slug,
              iconPath: brand.iconPath,
              size: 48,
            ),
            title: Text(
              brand.display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              drinkName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BrandDetailsPage(brand: brand)),
            ),
          )
        : Center(
            child: Text(
              isCurrentUser
                  ? 'No shops yet, add in home page'
                  : 'User has no shops yet',
              style: context.bobaText.empty,
            ),
          );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.inShell,
        title: widget.inShell ? const Text('You') : null,
        actions: [
          if (isCurrentUser)
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_rounded),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
            ),
          if (!isCurrentUser)
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'remove':
                    try {
                      await context.read<FriendState>().removeFriend(
                        widget.userId,
                      );
                      notify('Removed friend', SnackType.success);
                    } catch (_) {
                      notify(
                        'Could not remove friend. Try again.',
                        SnackType.error,
                      );
                    }
                    break;

                  case 'cancel_request':
                    try {
                      await context.read<FriendState>().removeFriend(
                        widget.userId,
                      );
                      notify('Friend request canceled', SnackType.success);
                    } catch (_) {
                      notify(
                        'Could not cancel request. Try again.',
                        SnackType.error,
                      );
                    }
                    break;

                  case 'reject_request':
                    try {
                      await context.read<FriendState>().rejectUser(
                        widget.userId,
                      );
                      notify('Friend request rejected', SnackType.success);
                    } catch (_) {
                      notify(
                        'Could not reject request. Try again.',
                        SnackType.error,
                      );
                    }
                    break;

                  case 'report':
                    await showReportDialog(
                      context: context,
                      contentType: 'user',
                      contentId: widget.userId,
                      reportedUserId: widget.userId,
                      title: 'Report this person',
                    );
                    break;
                }
              },
              itemBuilder: (_) {
                final items = <PopupMenuEntry<String>>[];

                if (friendStatus?.status == 'accepted') {
                  items.add(
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove friend'),
                    ),
                  );
                } else if (friendStatus?.status == 'pending') {
                  if (friendStatus!.requester.id == currentUser.id) {
                    items.add(
                      const PopupMenuItem(
                        value: 'cancel_request',
                        child: Text('Cancel friend request'),
                      ),
                    );
                  } else if (friendStatus.addressee.id == currentUser.id) {
                    items.add(
                      const PopupMenuItem(
                        value: 'reject_request',
                        child: Text('Reject friend request'),
                      ),
                    );
                  }
                }
                items.add(
                  const PopupMenuItem(value: 'report', child: Text('Report')),
                );
                return items;
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: widget.inShell ? BobaNavBar.clearance(context) : 24,
          ),
          child: Column(
            children: [
              CollectorCard(
                displayName: user.displayName,
                username: user.username,
                bio: user.bio,
                profileImagePath: user.profileImagePath,
                createdAt: user.createdAt,
                brandCount: stats.shopCount,
                drinkCount: stats.drinkCount,
                badgeCount: stats.badgeCount,
                badges: pinnedBadges.take(3).toList(),
                favorite: _isLoading ? const ShopTileSkeleton() : favTile,
                onEdit: isCurrentUser
                    ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsAccountPage(),
                        ),
                      )
                    : null,
                onBadgeTap: (_) {
                  if (isCurrentUser) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AchievementsPage(
                          userId: widget.userId,
                          pinMode: true,
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              if (friendBtn != null || viewBtn != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [?friendBtn, ?viewBtn],
                ),
              const SizedBox(height: 8),
              if (isCurrentUser) ...[
                const SizedBox(height: 8),
                LeaderboardPreview(userId: widget.userId),
                const SizedBox(height: 8),
              ],
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('Recent activity'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UserActivityPage(
                      userId: widget.userId,
                      isOwner: isCurrentUser,
                    ),
                  ),
                ),
              ),
              if (isCurrentUser) ...[
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.emoji_events_rounded),
                  title: const Text('Achievements'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AchievementsPage(userId: widget.userId),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.settings_rounded),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('About + Contact'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const AboutPage())),
                ),
              ],
            ],
          ),
        ),
      ),
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
          color: context.boba.outline,
          shape: BoxShape.circle,
        ),
      ),
      title: Container(width: 80, height: 12, color: context.boba.outline),
      subtitle: Container(
        width: 60,
        height: 10,
        color: context.boba.surfaceAlt,
        margin: EdgeInsets.only(top: 4),
      ),
    );
  }
}
