import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friendship.dart';
import 'package:bobadex/models/user.dart' as u;

class FriendState extends ChangeNotifier {
  final supabase = Supabase.instance.client;
  String? userId = '';
  u.User user = u.User.empty();

  List<Friendship> _friendships = [];

  List<Friendship> get allFriendships => _friendships;

  List<u.User> get friends => _friendships
    .where((f) => f.status == 'accepted')
    .map((f) => f.requester.id == userId ? f.addressee : f.requester)
    .toList()
    ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

  List<u.User> get sentRequests => _friendships
    .where((f) => f.status == 'pending' && f.requester.id == userId)
    .map((f) => f.addressee)
    .toList()
    ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

  List<u.User> get incomingRequests => _friendships
    .where((f) => f.status == 'pending' && f.addressee.id == userId)
    .map((f) => f.requester)
    .toList()
    ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

  void removeByUsers(String requesterId, String addresseeId) {
    _friendships.removeWhere((f) =>
      f.requester.id == requesterId && f.addressee.id == addresseeId);
  }

  Future<void> addUser(u.User addressee) async {
    _friendships.add(Friendship(id: '', status: 'pending', requester: user, addressee: addressee));
    notifyListeners();

    try {
      await supabase
        .from('friendships')
        .insert({
          'requester_id': userId,
          'addressee_id': addressee.id,
        });
    } catch (e) {
      print('Error adding user: $e');
      removeByUsers(userId!, addressee.id);
      rethrow;
    }
  }

  void reset() {
    _friendships.clear();
    notifyListeners();
  }

  Future<void> loadFromSupabase() async {
    userId = supabase.auth.currentUser?.id;
    final userResult = await supabase.from('users').select().eq('id', userId).single();
    user = u.User.fromJson(userResult);

    final results = await supabase
      .from('friendships')
      .select('''
        id,
        status,
        requester_id,
        addressee_id,
        requester:requester_id(id, username, display_name, profile_image_path),
        addressee:addressee_id(id, username, display_name, profile_image_path)
      ''')
      .or('requester_id.eq.$userId, addressee_id.eq.$userId');

    _friendships = (results as List).map((f) => Friendship.fromJson(f)).toList();

    notifyListeners();
  }
}