import 'package:bobadex/config/constants.dart';
import 'package:bobadex/models/account_stats.dart';
import 'package:bobadex/models/achievement.dart';
import 'package:bobadex/models/friendship.dart';
import 'package:bobadex/models/user.dart' as u;
import 'package:bobadex/pages/brand_details_page.dart';
import 'package:bobadex/pages/home_page.dart';
import 'package:bobadex/pages/setting_pages/settings_account_page.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/state/user_stats_cache.dart';
import 'package:bobadex/widgets/badge_picker_dialog.dart';
import 'package:bobadex/widgets/stat_box.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountViewPage extends StatefulWidget {
  final u.User user;

  const AccountViewPage ({
    super.key,
    required this.user,
  });

  @override
  State<AccountViewPage> createState() => _AccountViewPageState() ;
}

class _AccountViewPageState extends State<AccountViewPage> {
  bool _isLoading = false;
  AccountStats stats = AccountStats.emptyStats();
  List<Achievement> readOnlyBadges  = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String get brandThumbUrl => stats.topShopIcon.isNotEmpty
    ? Supabase.instance.client.storage
        .from('shop-media')
        .getPublicUrl('thumbs/${stats.topShopIcon.trim()}')
    : '';

  Future<void> _fetchData() async {
    final supabase = Supabase.instance.client;
    setState(() => _isLoading = true);
    try {
      final stats = await context.read<UserStatsCache>().getStats(widget.user.id);
      if (widget.user.id != supabase.auth.currentUser!.id) {
        final response = await supabase
          .from('user_achievements')
          .select('achievement:achievement_id(*)')
          .eq('user_id', widget.user.id)
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
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    final brandState = context.read<BrandState>();
    final friendState = context.watch<FriendState>();
    final brand = brandState.getBrand(stats.topShopSlug);
    final drinkName = stats.topDrinkName;
    final currentUser = userState.user;
    final isCurrentUser = currentUser.id == widget.user.id;
    final user = isCurrentUser ? currentUser : widget.user;
    final friendStatus = friendState.allFriendships.firstWhereOrNull((f) => f.requester.id == user.id || f.addressee.id == user.id);
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
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          children: [
            ThumbPic(
              url: user.thumbUrl,
              size: 140, 
              onTap: () => isCurrentUser 
                ?  Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SettingsAccountPage()))
                : null
              ),
            SizedBox(height: 12),
            Text(user.displayName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('@${user.username}', style: TextStyle(color: Colors.grey[700])),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (user.id != currentUser.id)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          !isFriendButtonEnabled(friendStatus, currentUser.id, user.id)
                            ? Colors.grey
                            : Constants.getThemeColor(userState.user.themeSlug).shade300
                        ),
                        foregroundColor: WidgetStatePropertyAll(Colors.white)
                      ),
                      onPressed: isFriendButtonEnabled(friendStatus, currentUser.id, user.id)
                        ? () async {
                          if (friendStatus == null) {
                            await friendState.addUser(widget.user);
                          } else if (friendStatus.status == 'pending' && friendStatus.requester.id == user.id) {
                            await friendState.acceptUser(widget.user.id);
                          }
                        }
                        : null,
                      child: Text(getFriendButtonText(friendStatus, currentUser.id, user.id)),
                    ),
                  ),
                if (user.id == currentUser.id)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SettingsAccountPage())
                      ),
                      child: Text('Edit Profile')
                    ),
                  ),
                if (user.id != currentUser.id)
                ElevatedButton(
                  onPressed: () {
                    isCurrentUser
                      ? Navigator.of(context).pop()
                      : Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => HomePage(user: user))
                      );
                  },
                  child: const Text('View Bobadex')
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(user.bio ?? 'No bio set', textAlign: TextAlign.center),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StatBox(label: 'Shops', value: _isLoading ? '...' : stats.shopCount.toString()),
                StatBox(label: 'Drinks', value: _isLoading ? '...' : stats.drinkCount.toString()),
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
                child: (brand != null)
                  ? ListTile(
                      leading: (brandThumbUrl.isNotEmpty)
                        ? CachedNetworkImage(
                          imageUrl: brandThumbUrl,
                          width: 50,
                          height: 50,
                          placeholder: (context, url) => CircularProgressIndicator(),
                        )
                        : Image.asset(
                          'lib/assets/default_icon.png',
                          fit: BoxFit.cover,
                        ),
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
              onTap: user.id == currentUser.id
                ? () {
                  showDialog(
                    context: context,
                    builder: (ctx) => BadgePickerDialog(
                      badges: unlockedBadges,
                      pinnedBadges: pinnedBadges,
                      onSave: (selected) async {
                        for (final a in unlockedBadges) {
                          final shouldPin = selected.contains(a.id);
                          if (achievementState.progressMap[a.id]?.pinned != shouldPin) {
                            await achievementState.setPinned(a.id);
                          }
                        }
                        if(context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  );
                }
                : null,
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: Row(
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
          ],
        ),
      )
    );
  }
}