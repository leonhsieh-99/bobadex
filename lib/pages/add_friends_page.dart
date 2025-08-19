import 'package:bobadex/config/constants.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/account_view_page.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/widgets/custom_search_bar.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart' as u;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class AddFriendsPage extends StatefulWidget {
  const AddFriendsPage ({super.key});

  @override
  State<AddFriendsPage> createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> {
  final _searchController = SearchController();
  final userId = Supabase.instance.client.auth.currentUser!.id;
  List<u.User> _searchResult = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final query = _searchController.text.trim();
      if (query.trim().length >= 2) {
        final response = await Supabase.instance.client
          .rpc('search_users_fuzzy', params: {'query': query});
        
        final results = (response as List)
          .where((e) => e['id'] != userId)
          .map((e) => u.User.fromJson(e))
          .toList();
        
        if (mounted) {
          setState(() {
            _searchResult = results;
          });
        } else {
          setState(() {
            _searchResult = [];
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<UserState>().user;
    final friendState = context.watch<FriendState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Friends'),
      ),
      body: Column(
        children: [
          CustomSearchBar(
            controller: _searchController,
            hintText: 'Search user\'s name or username'
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResult.length,
              itemBuilder: (context, idx) {
                final addressee = _searchResult[idx];
                final isFriend = friendState.friends.any((f) => f.id == addressee.id);
                final isPending = friendState.sentRequests.any((r) => r.id == addressee.id);
                final isDisabled = isFriend || isPending;
                return ListTile(
                  title: Text(addressee.username),
                  subtitle: Text(addressee.displayName),
                  leading: ThumbPic(url: addressee.imageUrl),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AccountViewPage(userId: addressee.id, user: addressee))
                  ), 
                  trailing: ElevatedButton(
                    onPressed: isDisabled
                      ? null 
                      : () async {
                      try {
                        friendState.addUser(addressee);
                      } catch (e) {
                        if (mounted) { notify('Error adding friend', SnackType.error); }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.getThemeColor(user.themeSlug).shade200,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    child: Text(
                      isFriend
                        ? 'Added'
                        : isPending
                          ? 'Pending'
                          : 'Add',
                    ),
                  ),
                );
              }
            )
          )
        ]
      ),
    );
  }
}