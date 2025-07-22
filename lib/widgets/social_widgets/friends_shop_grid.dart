import 'package:bobadex/config/constants.dart';
import 'package:bobadex/helpers/show_snackbar.dart';
import 'package:bobadex/models/friends_shop.dart';
import 'package:bobadex/pages/friends_shop_details_page.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      final response = await supabase.rpc('get_friends_shops', params: {'user_id': currentUserId});
      final data = response as List? ?? [];
      shopsData = data.map((json) => FriendsShop.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading shops $e');
      if(mounted) showAppSnackBar(context, 'Error loading shops, try again later', type: SnackType.error);
    }
    shopsData ??= [];
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _buildLoadingPearl(),
                childCount: 8,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 0.9,
              ),
            ),
          ),
        ],
      );
    }

    if (shopsData!.isEmpty) {
      return Center(
        child: Text('No shared shops yet', style: Constants.emptyListTextStyle),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildShopPearl(shopsData![i]),
              childCount: shopsData!.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: 0.9,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildLoadingPearl() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Grayed out circle
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 10),
        // Grayed-out text bars
        Container(
          height: 16,
          width: 70,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 12,
          width: 45,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildShopPearl(shop) {
    final brandState = context.read<BrandState>();
    final brand = brandState.getBrand(shop.brandSlug);
    final userState = context.read<UserState>();
    final themeColor = Constants.getThemeColor(userState.user.themeSlug);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FriendsShopDetailsPage(
              shop: shop,
              mostDrinksUser: shop.mostDrinksUser,
            ),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: themeColor.shade200,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: (shop.brandSlug == null || shop.brandSlug!.isEmpty) || (brand!.iconPath == null || brand.iconPath!.isEmpty)
                ? Image.asset(
                  'lib/assets/default_icon.png',
                  fit: BoxFit.cover,
                  )
                : CachedNetworkImage(
                  imageUrl: brand.thumbUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  placeholder: (context, _) => Container(
                    color: Colors.grey.shade200,
                  ),
                  errorWidget: (context, _, __) => Icon(Icons.store, size: 30, color: Colors.grey),
                ),
              )
          ),
          const SizedBox(height: 10),
          Text(
            shop.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 5),
          Text(
            'Avg: ${shop.avgRating.toStringAsFixed(1)}',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 5),
          Text(
            'Ratings: ${shop.friendsInfo.length.toString()}',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ],
      )
    );
  }
}