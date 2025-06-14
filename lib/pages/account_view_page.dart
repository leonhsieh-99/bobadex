import 'package:bobadex/models/user.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/widgets/stat_box.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountViewPage extends StatefulWidget {
  final User user;

  const AccountViewPage ({
    super.key,
    required this.user,
  });

  @override
  State<AccountViewPage> createState() => _AccountViewPageState() ;
}

class _AccountViewPageState extends State<AccountViewPage> {
  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    final user = userState.user;
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
                StatBox(label: 'Shops', value: userState.statistics['num_shops'].toString()),
                StatBox(label: 'Drinks', value: userState.statistics['num_drinks'].toString()),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Nav to bobadex
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