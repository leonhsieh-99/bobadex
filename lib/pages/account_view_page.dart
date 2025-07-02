import 'package:bobadex/models/account_stats.dart';
import 'package:bobadex/models/user.dart' as u;
import 'package:bobadex/pages/brand_details_page.dart';
import 'package:bobadex/pages/home_page.dart';
import 'package:bobadex/pages/setting_pages/settings_account_page.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/drink_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/state/user_stats_cache.dart';
import 'package:bobadex/widgets/stat_box.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    setState(() => _isLoading = true);
    try {
      final stats = await context.read<UserStatsCache>().getStats(widget.user.id);
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
    final shopState = context.watch<ShopState>();
    final shop = shopState.getShop(stats.topShopId);
    final drinkState = context.watch<DrinkState>();
    final brandState = context.read<BrandState>();
    final brand = brandState.getBrand(stats.topShopSlug);
    final drink = drinkState.getDrink(stats.topDrinkId);
    final currentUser = userState.user;
    final user = currentUser.id == widget.user.id ? currentUser : widget.user;
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          children: [
            ThumbPic(url: user.thumbUrl, size: 140),
            SizedBox(height: 12),
            Text(user.displayName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('@${user.username}', style: TextStyle(color: Colors.grey[700])),
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
              child: ListTile(
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
                title: Text(shop?.name ?? ''),
                subtitle: Text(drink?.name ?? ''),
              ),
            ),
            SizedBox(height: 6),
            Text('Badges', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBadge(icon: Icons.star, label: 'Starter', color: Colors.amber),
                SizedBox(width: 12),
                _buildBadge(icon: Icons.coffee, label: 'First Drink', color: Colors.brown),
                SizedBox(width: 12),
                _buildBadge(icon: Icons.group, label: 'Friend', color: Colors.blue),
                SizedBox(width: 12),
                _buildBadge(icon: Icons.photo_camera, label: 'Photographer', color: Colors.deepPurple),
              ],
            ),
            SizedBox(height: 16),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => HomePage(user: user))
                    );
                  },
                  child: const Text('View Bobadex')
                ),
              ],
            )
          ],
        ),
      )
    );
  }
}

Widget _buildBadge({required IconData icon, required String label, required Color color}) {
  return Column(
    children: [
      CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        radius: 22,
        child: Icon(icon, color: color, size: 28),
      ),
      SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    ],
  );
}
