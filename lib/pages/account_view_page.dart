import 'package:bobadex/config/constants.dart';
import 'package:bobadex/models/user.dart' as u;
import 'package:bobadex/pages/home_page.dart';
import 'package:bobadex/pages/setting_pages/settings_account_page.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/state/user_stats_cache.dart';
import 'package:bobadex/widgets/stat_box.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  Map<String, dynamic> stats = Constants.emptyStats;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    if (context.read<UserState>().user.id == widget.user.id) {
      setState(() {
        stats = context.read<UserState>().statistics;
        _isLoading = false;
      });
    } else {
      final stats = await context.read<UserStatsCache>().getStats(widget.user.id);
      setState(() {
        this.stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
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
            Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StatBox(label: 'Shops', value: _isLoading ? '...' : stats['num_shops'].toString()),
                StatBox(label: 'Drinks', value: _isLoading ? '...' : stats['num_drinks'].toString()),
              ],
            ),
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