import 'package:bobadex/models/brand_stats.dart';
import 'package:bobadex/models/user_stats.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/account_view_page.dart';
import 'package:bobadex/pages/brand_details_page.dart';
import 'package:bobadex/ui/components/boba_nav_bar.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key, this.embedded = false});

  final bool embedded;

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
      final userResponse = await Supabase.instance.client.rpc(
        'get_user_rankings',
      );
      final brandResponse = await Supabase.instance.client.rpc(
        'get_brand_rankings',
      );
      return [
        (userResponse as List).map((json) => UserStats.fromJson(json)).toList(),
        (brandResponse as List)
            .map((json) => BrandStats.fromJson(json))
            .toList(),
      ];
    } catch (e) {
      debugPrint('Error loading rankings: $e');
      notify('Error loading rankings', SnackType.error);
    }
    return [[], []];
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<List<List<dynamic>>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildSkeletonLoader(context);
        final rankings = snapshot.data!;
        final userRankings = rankings[0];
        final brandRankings = rankings[1];
        final bottom = widget.embedded ? BobaNavBar.clearance(context) : 24.0;
        return TabBarView(
          children: [
            ListView.builder(
              padding: EdgeInsets.only(bottom: bottom),
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          AccountViewPage(userId: user.id, user: user),
                    ),
                  ),
                );
              },
            ),
            brandRankings.isEmpty
                ? Center(
                    child: Text(
                      'No brand rankings yet',
                      style: context.bobaText.empty,
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: bottom),
                    itemCount: brandRankings.length,
                    itemBuilder: (context, index) {
                      final brand = brandRankings[index];
                      return ListTile(
                        minTileHeight: 60,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: Text(
                                brand.display,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  brand.avgRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
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
                            style: TextStyle(
                              fontSize: 13,
                              color: context.boba.inkMuted,
                            ),
                          ),
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BrandDetailsPage(brand: brand),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        );
      },
    );

    return DefaultTabController(
      length: 2,
      child: widget.embedded
          ? Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Users'),
                    Tab(text: 'Brands'),
                  ],
                ),
                Expanded(child: body),
              ],
            )
          : Scaffold(
              appBar: AppBar(
                title: const Text('Rankings'),
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Users'),
                    Tab(text: 'Brands'),
                  ],
                ),
              ),
              body: body,
            ),
    );
  }
}

Widget _buildSkeletonLoader(BuildContext context) {
  return TabBarView(
    children: [
      ListView.builder(
        itemCount: 8,
        itemBuilder: (_, _) => ListTile(
          minTileHeight: 60,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.boba.outline,
              shape: BoxShape.circle,
            ),
          ),
          title: Container(
            width: double.infinity,
            height: 18,
            color: context.boba.outline,
            margin: const EdgeInsets.only(right: 80),
          ),
          subtitle: Container(
            width: 100,
            height: 12,
            color: context.boba.surfaceAlt,
            margin: const EdgeInsets.only(top: 8),
          ),
          trailing: Container(
            width: 28,
            height: 18,
            color: context.boba.outline,
          ),
        ),
      ),
      ListView.builder(
        itemCount: 8,
        itemBuilder: (_, _) => ListTile(
          title: Row(
            children: [
              Expanded(
                flex: 6,
                child: Container(
                  height: 18,
                  color: context.boba.outline,
                  margin: const EdgeInsets.only(right: 16),
                ),
              ),
              Container(
                width: 28,
                height: 18,
                color: context.boba.outline,
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              Container(width: 18, height: 18, color: context.boba.outline),
            ],
          ),
          subtitle: Container(
            width: 100,
            height: 12,
            color: context.boba.surfaceAlt,
            margin: const EdgeInsets.only(top: 8),
          ),
        ),
      ),
    ],
  );
}
