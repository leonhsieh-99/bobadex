import 'package:bobadex/models/brand_stats.dart';
import 'package:bobadex/models/user_stats.dart';
import 'package:bobadex/pages/account_view_page.dart';
import 'package:bobadex/pages/brand_details_page.dart';
import 'package:bobadex/pages/splash_page.dart';
// import 'package:bobadex/widgets/rating_picker.dart';
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
      print('Error loading rankings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Error loading rankings'))
      );
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
            if (!snapshot.hasData) return SplashPage();
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
                      leading: ThumbPic(url: user.thumbUrl),
                      subtitle: Text('@${user.username}'),
                      trailing: Text(
                        user.shopCount.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AccountViewPage(user: user))),
                    );
                  }
                ),
                ListView.builder(
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
                          '(${brand.shopCount} reviews)',
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