import 'package:bobadex/models/user_stats.dart';
import 'package:bobadex/pages/account_view_page.dart';
import 'package:bobadex/pages/rankings_page.dart';
import 'package:bobadex/ui/components/boba_button.dart';
import 'package:bobadex/ui/components/boba_card.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardPreview extends StatefulWidget {
  const LeaderboardPreview({super.key, required this.userId});

  final String userId;

  @override
  State<LeaderboardPreview> createState() => _LeaderboardPreviewState();
}

class _LeaderboardPreviewState extends State<LeaderboardPreview> {
  late Future<List<UserStats>> _rankings;

  @override
  void initState() {
    super.initState();
    _rankings = _load();
  }

  Future<List<UserStats>> _load() async {
    try {
      final rows = await Supabase.instance.client.rpc(
        'get_user_rankings',
        params: {'p_metric': 'brands'},
      );
      return (rows as List)
          .map((json) => UserStats.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      debugPrint('leaderboard preview failed: $e');
      return [];
    }
  }

  void _openBoard() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RankingsPage()));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserStats>>(
      future: _rankings,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const BobaCard(child: SizedBox(height: 88));
        }
        final rows = snapshot.data ?? const <UserStats>[];
        if (rows.isEmpty || snapshot.hasError) return const SizedBox.shrink();
        final top = rows.where((row) => row.rank <= 3).take(3).toList();
        UserStats? me;
        for (final row in rows) {
          if (row.id == widget.userId) me = row;
        }
        final meInTop = me != null && me.rank <= 3;
        return BobaCard(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Leaderboard',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  BobaButton(
                    label: 'See all',
                    size: BobaButtonSize.small,
                    variant: BobaButtonVariant.tertiary,
                    onPressed: _openBoard,
                  ),
                ],
              ),
              Text(
                'Most brands',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.boba.inkMuted),
              ),
              const SizedBox(height: 8),
              for (final row in top)
                _RankLine(
                  rank: row.rank,
                  name: row.displayName,
                  value: row.metricValue,
                  onTap: row.id == widget.userId
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AccountViewPage(userId: row.id, user: row),
                          ),
                        ),
                ),
              if (me != null && !meInTop) ...[
                Divider(height: 16, color: context.boba.outline),
                _RankLine(rank: me.rank, name: 'You', value: me.metricValue),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RankLine extends StatelessWidget {
  const _RankLine({
    required this.rank,
    required this.name,
    required this.value,
    this.onTap,
  });

  final int rank;
  final String name;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '$rank',
                style: context.bobaText.numeral(fontSize: 16),
              ),
            ),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text('$value', style: context.bobaText.numeral(fontSize: 16)),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
