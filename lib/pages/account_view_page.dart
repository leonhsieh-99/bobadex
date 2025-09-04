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
import 'package:bobadex/widgets/report_widget.dart';
import 'package:bobadex/widgets/stat_box.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
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

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (!isCurrentUser)
            PopupMenuButton(
              onSelected: (value) {
                switch(value) {
                  case 'report':
                    showDialog(
                      context: context,
                      builder: (_) => ReportDialog(
                        contentType: 'user',
                        contentId: widget.userId,
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'report',
                  child: Text('report')
                )
              ]
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ThumbPic(
                path: user.profileImagePath,
                size: 140, 
                onTap: isCurrentUser 
                  ?  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SettingsAccountPage()))
                  : null
                ),
              SizedBox(height: 12),
              Text(user.displayName, textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('@${user.username}', style: TextStyle(color: Colors.grey[700])),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.userId != currentUser.id)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            !isFriendButtonEnabled(friendStatus, currentUser.id, widget.userId)
                              ? Colors.grey
                              : Constants.getThemeColor(userState.current.themeSlug).shade300
                          ),
                          foregroundColor: WidgetStatePropertyAll(Colors.white)
                        ),
                        onPressed: isFriendButtonEnabled(friendStatus, currentUser.id, widget.userId)
                          ? () async {
                            if (friendStatus == null) {
                              await friendState.addUser(user);
                            } else if (friendStatus.status == 'pending' && friendStatus.requester.id == widget.userId) {
                              await friendState.acceptUser(widget.userId);
                            }
                          }
                          : null,
                        child: Text(getFriendButtonText(friendStatus, currentUser.id, widget.userId)),
                      ),
                    ),
                  if (widget.userId == currentUser.id)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => SettingsAccountPage())
                        ),
                        child: Text('Edit Profile')
                      ),
                    ),
                  if (widget.userId != currentUser.id)
                    ElevatedButton(
                      onPressed: (!isCurrentUser && _user != null)
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => HomePage(userId: _user!.id)))
                          : null,
                      child: const Text('View Bobadex'),
                    ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                (user.bio == null || user.bio!.trim().isEmpty)
                    ? 'No bio set'
                    : user.bio!,
                textAlign: TextAlign.center,
                style: (user.bio == null || user.bio!.isEmpty) ? Constants.emptyListTextStyle : null,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _isLoading
                  ? [StatBoxSkeleton(), StatBoxSkeleton()]
                  : [
                      StatBox(label: 'Shops', value: stats.shopCount.toString()),
                      StatBox(label: 'Drinks', value: stats.drinkCount.toString()),
                    ],
              ),
              Divider(height: 32),
              Text('Favorite Shop', style: TextStyle(fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: brand != null 
                  ? () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => BrandDetailsPage(brand: brand)
                  ))
                  : null,
                child: SizedBox(
                  height: 60,
                  child: _isLoading
                    ? ShopTileSkeleton()
                    : (brand != null)
                      ? ListTile(
                          leading: IconPic(path: brand.iconPath, size: 50),
                          title: Text(brand.display),
                          subtitle: Text(drinkName),
                        )
                      : Center( child: Text( isCurrentUser ? 'No shops yet, add in home page' : 'User has no shops yet', style: Constants.emptyListTextStyle))
                )
              ),
              SizedBox(height: 6),
              Text('Badges', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              GestureDetector(
                onTap: widget.userId == currentUser.id
                  ? () {
                    showDialog(
                      context: context,
                      builder: (ctx) => BadgePickerDialog(
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
                      ),
                    );
                  }
                  : null,
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: _isLoading
                    ? BadgeRowSkeleton()
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: pinnedBadges.isNotEmpty
                        ? pinnedBadges
                          .map((a) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Tooltip(
                              message: (a.isHidden && !isCurrentUser) ? 'Hidden ? ? ?' : a.description,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Constants.badgeBgColor,
                                      backgroundImage: AssetImage(
                                        (a.iconPath != null && a.iconPath!.isNotEmpty)
                                          ? a.iconPath!
                                          : 'lib/assets/badges/default_badge.png'
                                      ),
                                      radius: 22,
                                    ),
                                    Text(
                                      a.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w300,
                                        fontSize: 9,
                                      ),
                                    )
                                  ]
                                )
                            )
                          ))
                          .toList()
                        : [
                            Text( isCurrentUser ? 'No badges yet, tap to pin your badges' : 'User has no badges yet', style: Constants.emptyListTextStyle),
                          ],
                    ),
                ),
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
