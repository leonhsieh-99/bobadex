import 'package:bobadex/config/constants.dart';
import 'package:bobadex/models/user.dart';
import 'package:bobadex/pages/account_view_page.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/tea_room_state.dart';
import 'package:bobadex/widgets/custom_search_bar.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddTeaRoomMembersPage extends StatefulWidget {
  final String roomId;
  const AddTeaRoomMembersPage({super.key, required this.roomId});

  @override
  State<AddTeaRoomMembersPage> createState() => _AddTeaRoomMembersPageState();
}

class _AddTeaRoomMembersPageState extends State<AddTeaRoomMembersPage> {
  final _searchController = SearchController();

  List<User> get _friends => context.watch<FriendState>().friends;
  List<User> get filteredFriends {
    final searchQuery = _searchController.text.trim();
    if (searchQuery.isEmpty) return _friends;
    return _friends.where(
      (f) => f.displayName.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
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

  void _onSearchChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final teaRoomState = context.watch<TeaRoomState>();
    final members = teaRoomState.getMembers(widget.roomId)?.map((u) => u.id).toSet() ?? {};

    return Scaffold(
      appBar: AppBar(title: Text('Add Tea Room Members')),
      body: Column(
        children: [
          CustomSearchBar(controller: _searchController, hintText: 'Search friends'),
          if (_friends.isEmpty)
            Expanded(child: Center(child: Text('No friends yet', style: Constants.emptyListTextStyle))),
          Expanded(
            child: ListView.builder(
              itemCount: filteredFriends.length,
              itemBuilder: (context, index) {
                final friend = filteredFriends[index];
                final alreadyMember = members.contains(friend.id);

                return ListTile(
                  title: Text(friend.displayName),
                  leading: ThumbPic(url: friend.thumbUrl),
                  subtitle: Text('@${friend.username}'),
                  trailing: alreadyMember
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : IconButton(
                        icon: Icon(Icons.person_add_alt_1),
                        onPressed: () async {
                          try {
                            await teaRoomState.addMember(widget.roomId, friend);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Added ${friend.displayName}'))
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e'))
                            );
                          }
                        },
                      ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AccountViewPage(user: friend))
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
