import 'package:bobadex/models/brand_stats.dart';
import 'package:bobadex/models/user_stats.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/account_view_page.dart';
import 'package:bobadex/pages/brand_details_page.dart';
import 'package:bobadex/ui/components/boba_chip.dart';
import 'package:bobadex/ui/components/boba_nav_bar.dart';
import 'package:bobadex/ui/components/collector_card.dart';
import 'package:bobadex/ui/components/rating_text.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/state/rankings_cache.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:bobadex/widgets/brand_mark.dart';
import 'package:flutter/material.dart';

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _userMetric = 'brands';
  String _brandMetric = 'locations';
  late Future<List<UserStats>> _users;
  Future<List<BrandStats>>? _brands;

  static const _userMetrics = [
    ('brands', 'Brands'),
    ('badges', 'Badges'),
  ];

  static const _brandMetrics = [
    ('locations', 'Locations'),
    ('score', 'Score'),
    ('rating', 'Rating'),
    ('collected', 'Collected'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index == 1) {
        _brands ??= RankingsCache.brandRankings(_brandMetric);
      }
      if (!_tabs.indexIsChanging && mounted) setState(() {});
    });
    _users = _loadUsers();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<List<UserStats>> _loadUsers() async {
    try {
      return await RankingsCache.userRankings(_userMetric);
    } catch (e) {
      debugPrint('Error loading user rankings: $e');
      notify('Error loading rankings', SnackType.error);
      return [];
    }
  }

  Future<List<BrandStats>> _loadBrands() async {
    try {
      return await RankingsCache.brandRankings(_brandMetric);
    } catch (e) {
      debugPrint('Error loading brand rankings: $e');
      notify('Error loading rankings', SnackType.error);
      return [];
    }
  }

  void _selectUserMetric(String metric) {
    if (metric == _userMetric) return;
    setState(() {
      _userMetric = metric;
      _users = _loadUsers();
    });
  }

  void _selectBrandMetric(String metric) {
    if (metric == _brandMetric) return;
    setState(() {
      _brandMetric = metric;
      _brands = _loadBrands();
    });
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _tabs.index == 0 ? _userMetrics : _brandMetrics;
    final selected = _tabs.index == 0 ? _userMetric : _brandMetric;
    final bottom = widget.embedded ? BobaNavBar.clearance(context) : 24.0;
    final chips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          for (final metric in metrics) ...[
            BobaChip(
              label: metric.$2,
              selected: selected == metric.$1,
              onTap: () => _tabs.index == 0
                  ? _selectUserMetric(metric.$1)
                  : _selectBrandMetric(metric.$1),
            ),
            const SizedBox(width: BobaSpace.x2),
          ],
        ],
      ),
    );
    final pages = TabBarView(
      controller: _tabs,
      children: [
        FutureBuilder<List<UserStats>>(
          future: _users,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return _skeleton(context);
            return _userList(snapshot.data!, bottom);
          },
        ),
        FutureBuilder<List<BrandStats>>(
          future: _brands,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return _skeleton(context);
            return _brandList(snapshot.data!, bottom);
          },
        ),
      ],
    );

    final body = Column(
      children: [
        chips,
        Expanded(child: pages),
      ],
    );

    if (widget.embedded) {
      return Column(
        children: [
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Collectors'),
              Tab(text: 'Brands'),
            ],
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Collectors'),
            Tab(text: 'Brands'),
          ],
        ),
      ),
      body: body,
    );
  }

  Widget _userList(List<UserStats> users, double bottom) {
    final board = users.where((user) => user.rank <= 200).toList();
    UserStats? you;
    for (final user in users) {
      if (user.rank > 200) you = user;
    }
    if (board.isEmpty && you == null) {
      return Center(
        child: Text('No collectors yet', style: context.bobaText.empty),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.only(bottom: bottom),
      itemCount: board.length + (you == null ? 0 : 1),
      itemBuilder: (context, index) {
        final user = you != null && index == board.length ? you : board[index];
        final label = you != null && index == board.length
            ? 'You'
            : user.displayName;
        return CollectorCard(
          variant: CollectorCardVariant.compact,
          displayName: label,
          username: user.username,
          profileImagePath: user.profileImagePath,
          caption: user.username.isEmpty
              ? '#${user.rank}'
              : '#${user.rank} · @${user.username}',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AccountViewPage(userId: user.id, user: user),
            ),
          ),
          trailing: Text(
            user.metricValue.toString(),
            style: context.bobaText.numeral(fontSize: 20),
          ),
        );
      },
    );
  }

  Widget _brandList(List<BrandStats> brands, double bottom) {
    if (brands.isEmpty) {
      return Center(
        child: Text(
          'No brands on this board yet',
          style: context.bobaText.empty,
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.only(bottom: bottom),
      itemCount: brands.length,
      itemBuilder: (context, index) {
        final brand = brands[index];
        final rated = _brandMetric == 'rating' || _brandMetric == 'score';
        return ListTile(
          minTileHeight: 60,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          leading: BrandMark(
            name: brand.display,
            slug: brand.slug,
            iconPath: brand.iconPath,
            size: 40,
          ),
          title: Text(
            brand.display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            _brandSubtitle(brand),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.boba.inkMuted),
          ),
          trailing: _brandMetric == 'rating'
              ? RatingText(value: brand.avgRating)
              : Text(
                  rated
                      ? brand.metricValue.toStringAsFixed(1)
                      : brand.metricValue.round().toString(),
                  style: context.bobaText.numeral(fontSize: 20),
                ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => BrandDetailsPage(brand: brand)),
          ),
        );
      },
    );
  }

  String _brandSubtitle(BrandStats brand) {
    final ratings = brand.shopCount == 1
        ? '1 rating'
        : '${brand.shopCount} ratings';
    return switch (_brandMetric) {
      'locations' => 'locations',
      'collected' => 'collectors',
      'rating' || 'score' => ratings,
      _ => ratings,
    };
  }

  Widget _skeleton(BuildContext context) {
    return ListView.builder(
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
          height: 16,
          color: context.boba.outline,
          margin: const EdgeInsets.only(right: 80),
        ),
        subtitle: Container(
          height: 12,
          width: 80,
          color: context.boba.surfaceAlt,
          margin: const EdgeInsets.only(top: 8),
        ),
      ),
    );
  }
}
