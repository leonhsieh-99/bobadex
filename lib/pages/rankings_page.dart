import 'package:bobadex/config/constants.dart';
import 'package:bobadex/models/brand_stats.dart';
import 'package:bobadex/models/user_stats.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/account_view_page.dart';
import 'package:bobadex/pages/brand_details_page.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RankingsPage extends StatefulWidget {
  const RankingsPage({
    super.key,
  });

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage> {
  late Future<List<List<dynamic>>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = fetchRankingStats();
  }

  Future<List<List<dynamic>>> fetchRankingStats() async {
    try {
      final userResponse = await Supabase.instance.client
        .rpc('get_user_rankings');
      final brandResponse = await Supabase.instance.client
        .rpc('get_brand_rankings');
      return [
        (userResponse as List).map((json) => UserStats.fromJson(json)).toList(),
        (brandResponse as List).map((json) => BrandStats.fromJson(json)).toList(),
      ];
    } catch (e) {
      debugPrint('Error loading rankings: $e');
      notify('Error loading rankings', SnackType.error);
    }
    return [[],[]];
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rankings'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Brands'),
            ],
          ),
        ),
        body: FutureBuilder<List<List<dynamic>>>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return _buildSkeletonLoader();
            final rankings = snapshot.data!;
            final userRankings = rankings[0];
            final brandRankings = rankings[1];
            return TabBarView(
              children: [
                ListView.builder(
                  itemCount: userRankings.length,
                  itemBuilder: (context, index) {
                    final user = userRankings[index];
                    return ListTile(
                      minTileHeight: 60,
                      title: Text(user.displayName),
                      leading: ThumbPic(path: user.profileImagePath),
                      subtitle: Text('@${user.username}'),
                      trailing: Text(
                        user.shopCount.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AccountViewPage(userId: user.id, user: user))),
                    );
                  }
                ),
                brandRankings.isEmpty
                  ? Center(
                    child: Text(
                      'No user rankings yet',
                      style: Constants.emptyListTextStyle,
                    ),
                  )
                  : ListView.builder(
                    itemCount: brandRankings.length,
                    itemBuilder: (context, index) {
                      final brand = brandRankings[index];
                      return ListTile(
                        minTileHeight: 60,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        title: Row(
                          children: [
                            Expanded(
                              flex: 6, // 60% of the row
                              child: Text(
                                brand.display,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  brand.avgRating.toStringAsFixed(1),
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                SizedBox(width: 4),
                                SvgPicture.asset(
                                  'lib/assets/icons/star.svg',
                                  width: 18,
                                  height: 18,
                                ),
                              ],
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '(${brand.shopCount} ratings)',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => BrandDetailsPage(brand: brand))
                        ),
                      );
                    }
                  ),
              ]
            );
          }
        )
      )
    );
  }
}

Widget _buildSkeletonLoader() {
  // Shows a fake list with greyed out blocks
  return TabBarView(
    children: [
      // Users skeleton
      ListView.builder(
        itemCount: 8,
        itemBuilder: (_, __) => ListTile(
          minTileHeight: 60,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          title: Container(
            width: double.infinity,
            height: 18,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.only(right: 80),
          ),
          subtitle: Container(
            width: 100,
            height: 12,
            color: Colors.grey.shade200,
            margin: const EdgeInsets.only(top: 8),
          ),
          trailing: Container(
            width: 28,
            height: 18,
            color: Colors.grey.shade300,
          ),
        ),
      ),
      // Brands skeleton
      ListView.builder(
        itemCount: 8,
        itemBuilder: (_, __) => ListTile(
          title: Row(
            children: [
              Expanded(
                flex: 6,
                child: Container(
                  height: 18,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.only(right: 16),
                ),
              ),
              Container(
                width: 28,
                height: 18,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              Container(
                width: 18,
                height: 18,
                color: Colors.grey.shade300,
              ),
            ],
          ),
          subtitle: Container(
            width: 100,
            height: 12,
            color: Colors.grey.shade200,
            margin: const EdgeInsets.only(top: 8),
          ),
        ),
      ),
    ]
  );
}
