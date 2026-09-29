import 'package:bobadex/models/friends_shop.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/shared_brand_page.dart';
import 'package:bobadex/ui/components/boba_nav_bar.dart';
import 'package:bobadex/ui/components/shared_brand_tile.dart';
import 'package:bobadex/ui/components/skeleton_box.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsShopGrid extends StatefulWidget {
  const FriendsShopGrid({super.key});

  @override
  State<FriendsShopGrid> createState() => _FriendsShopGridState();
}

class _FriendsShopGridState extends State<FriendsShopGrid> {
  bool _loading = true;
  List<FriendsShop>? shopsData;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser!.id;
    try {
      final response = await supabase.rpc(
        'get_friends_shops',
        params: {'user_id': currentUserId},
      );
      final data = response as List? ?? [];
      shopsData = data.map((json) => FriendsShop.fromJson(json)).toList()
        ..sort((a, b) {
          final byFriends = b.friendsInfo.length.compareTo(
            a.friendsInfo.length,
          );
          if (byFriends != 0) return byFriends;
          return b.avgRating.compareTo(a.avgRating);
        });
    } catch (e) {
      debugPrint('Error loading shops $e');
      notify('Error loading shops, try again later', SnackType.error);
    }
    shopsData ??= [];
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = BobaNavBar.clearance(context);
    if (_loading) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) => const BobaCardSkeleton(),
                childCount: 6,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
            ),
          ),
        ],
      );
    }

    final items = shopsData ?? const <FriendsShop>[];
    if (items.isEmpty) {
      return Center(
        child: Text('No shared brands yet', style: context.bobaText.empty),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((context, i) {
              final shop = items[i];
              return SharedBrandTile(
                shop: shop,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SharedBrandPage(
                        shop: shop,
                        mostDrinksUser: shop.mostDrinksUser,
                      ),
                    ),
                  );
                },
              );
            }, childCount: items.length),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
          ),
        ),
      ],
    );
  }
}

class BobaCardSkeleton extends StatelessWidget {
  const BobaCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SkeletonCircle(size: 56),
        SizedBox(height: 12),
        SkeletonBox(width: 80, height: 14),
        SizedBox(height: 8),
        SkeletonBox(width: 48, height: 12),
      ],
    );
  }
}
