import 'package:bobadex/models/user.dart';
import 'package:bobadex/pages/account_view_page.dart';
import 'package:bobadex/pages/add_friends_page.dart';
import 'package:bobadex/pages/friend_requests_page.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/widgets/custom_search_bar.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage ({
    super.key,
  });

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final _searchController = SearchController();

  List<User> get _friends {
    return context.watch<FriendState>().friends;
  }

  List<User> get filteredFriends {
    final searchQuery = _searchController.text.trim();
    if (searchQuery.isEmpty) return _friends;
    return _friends.where((f) => f.displayName.toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final friendState = context.watch<FriendState>();
    final incomingRequests = friendState.incomingRequests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends List'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: incomingRequests.isNotEmpty,
              backgroundColor: Colors.red,
              label: Text(
                incomingRequests.length.toString(),
                style: Constants.badgeLabelStyle,
              ),
              child: const Icon(Icons.mail_outline),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FriendRequestsPage()
                )
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          CustomSearchBar(
            controller: _searchController,
            hintText: 'Search friends',
          ),
          ListTile(
            title: Text('Add Friend', style: TextStyle(fontWeight: FontWeight.bold)),
            leading: Icon(Icons.add),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddFriendsPage())),
          ),
          if (_friends.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No friends yet',
                  style: Constants.emptyListTextStyle,
                )
              )
            ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredFriends.length,
              itemBuilder: (context, index) {
                final friend = filteredFriends[index];
                return ListTile(
                  title: Text(friend.displayName),
                  leading: ThumbPic(path: friend.profileImagePath, initials: friend.displayName),
                  subtitle: Text('@${friend.username}'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AccountViewPage(userId: friend.id, user: friend))),
                );
              },
            ),
          ),
        ],
      )
    );
  }
}