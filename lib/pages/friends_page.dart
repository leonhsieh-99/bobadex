import 'package:bobadex/pages/add_friends_page.dart';
import 'package:flutter/material.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage ({
    super.key,
  });

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends List'),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade100),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              title: const Text('Add Friends'),
              leading: Icon(Icons.people),
              trailing: Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddFriendsPage())),
            ),
          ),
          Expanded(child: ListView(
            children: [
            ],
          ))
        ],
      )
    );
  }
}