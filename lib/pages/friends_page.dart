import 'package:bobadex/models/user.dart';
import 'package:bobadex/pages/account_view_page.dart';
import 'package:bobadex/pages/add_friends_page.dart';
import 'package:bobadex/pages/friend_requests_page.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/ui/components/boba_nav_bar.dart';
import 'package:bobadex/ui/components/empty_state.dart';
import 'package:bobadex/widgets/custom_search_bar.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bobadex/ui/theme/boba_context.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final _searchController = SearchController();

  List<User> filteredFriends(List<User> friends) {
    final searchQuery = _searchController.text.trim();
    if (searchQuery.isEmpty) return friends;
    return friends
        .where(
          (f) =>
              f.displayName.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
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
    final friends = filteredFriends(friendState.friends);
    final body = Column(
      children: [
        CustomSearchBar(
          controller: _searchController,
          hintText: 'Search friends',
        ),
        ListTile(
          title: const Text(
            'Add Friend',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: const Icon(Icons.person_add_rounded),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddFriendsPage()),
          ),
        ),
        Expanded(
          child: friendState.friends.isEmpty
              ? const EmptyState(
                  title: 'No friends yet',
                  body: 'Add someone to share shops and drinks.',
                )
              : friends.isEmpty
              ? const EmptyState(title: 'No friends found')
              : ListView.builder(
                  padding: EdgeInsets.only(
                    bottom: widget.embedded
                        ? BobaNavBar.clearance(context)
                        : 24,
                  ),
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return ListTile(
                      title: Text(friend.displayName),
                      leading: ThumbPic(
                        path: friend.profileImagePath,
                        initials: friend.displayName,
                      ),
                      subtitle: Text('@${friend.username}'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AccountViewPage(userId: friend.id, user: friend),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends List'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: incomingRequests.isNotEmpty,
              backgroundColor: context.boba.danger,
              label: Text(
                incomingRequests.length.toString(),
                style: context.bobaText.badge,
              ),
              child: const Icon(Icons.mail_outline_rounded),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FriendRequestsPage()),
              );
            },
          ),
        ],
      ),
      body: body,
    );
  }
}
