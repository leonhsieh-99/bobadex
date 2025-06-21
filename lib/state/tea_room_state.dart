import 'package:bobadex/config/constants.dart';
import 'package:bobadex/models/tea_room.dart';
import 'package:bobadex/models/tea_room_shop.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as u;

class TeaRoomState extends ChangeNotifier {
  List<TeaRoom> teaRooms = [];
  Map<String, List<u.User>> teaRoomMembers = {};
  Map<String, List<TeaRoomShop>> teaRoomShops = {};

  List<TeaRoom> get all => teaRooms;

  // ------------ TEA ROOMS MANAGEMENT --------------

  TeaRoom getTeaRoom(String roomId) {
    return teaRooms.firstWhere((r) => r.id == roomId);
  }
  Future<void> update(TeaRoom teaRoom) async {
    final index = teaRooms.indexWhere((tr) => tr.id == teaRoom.id);
    final temp = teaRooms[index];
    teaRooms[index] = teaRoom;
    notifyListeners();

    try {
      Supabase.instance.client
        .from('tea_rooms')
        .update({
          'name': teaRoom.name,
          'description': teaRoom.description,
          'owner_id': teaRoom.ownerId,
          'room_image_path': teaRoom.roomImagePath,
        });
    } catch (e) {
      print('update failed');
      teaRooms[index] = temp;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> add(TeaRoom teaRoom, u.User user) async {
    if (teaRooms.length >= Constants.teaRoomCap) {
      throw Exception('Tea room limit reached');
    }
    final tempId = DateTime.now().toIso8601String();
    teaRooms.add(teaRoom.copyWith(id: tempId));
    notifyListeners();

    try {
      final response = await Supabase.instance.client
        .from('tea_rooms')
        .insert({
          'name': teaRoom.name,
          'description': teaRoom.description,
          'owner_id': teaRoom.ownerId,
          'room_image_path': teaRoom.roomImagePath,
        }).select().single();

      final index = teaRooms.indexWhere((t) => t.id == tempId);
      if (index != -1) {
        teaRooms[index] = TeaRoom.fromJson(response);
      } else {
        teaRooms.add(TeaRoom.fromJson(response));
      }
      final newRoomId = response['id'] as String;
      teaRoomMembers[newRoomId] = [];
      addMember(response['id'], user);
      notifyListeners();
    } catch (e) {
      print('insert failed: $e');
      teaRooms.removeWhere((t) => t.id == tempId);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> delete(String roomId) async {
    final index = teaRooms.indexWhere((tr) => tr.id == roomId);
    final temp = teaRooms[index];
    teaRooms.removeAt(index);
    notifyListeners();

    try {
      await Supabase.instance.client
        .from('tea_rooms')
        .delete()
        .eq('room_id', roomId);
    } catch (e) {
      print('Delete failed: $e');
      teaRooms.insert(index, temp);
      notifyListeners();
      rethrow;
    }
  }

  // ----------- MEMBER MANAGEMENT ----------------

  List<u.User>? getMembers(String roomId) {
    return teaRoomMembers.containsKey(roomId) ? teaRoomMembers[roomId] : null;
  }

  u.User? getMember(String roomId, String userId) {
    final members = getMembers(roomId);
    return members?.firstWhereOrNull((u) => u.id == userId);
  }

  Future<void> addMember(String roomId, u.User user) async {
    if (getMembers(roomId) == null) throw Exception('Room id error');
    if (getMember(roomId, user.id) != null) throw Exception(('Member already exists'));
    if (teaRoomMembers[roomId]!.length >= Constants.teaRoomMemberCap) {
      throw Exception('Tea room member limit reached');
    }
    teaRoomMembers[roomId]!.add(user);
    notifyListeners();

    try {
      await Supabase.instance.client
        .from('tea_room_members')
        .insert({
          'room_id': roomId,
          'user_id': user.id,
        }).select().single();
      
      await loadShops(roomId);
    } catch (e) {
      print('Insert failed: $e');
      teaRoomMembers[roomId]!.removeWhere((m) => m.id == user.id);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadMembers() async {
    final supabase = Supabase.instance.client;
    final membersResponse = await supabase
      .rpc('get_tea_rooms_with_members', params: {'user_id': supabase.auth.currentUser!.id});

    teaRoomMembers.clear();
    for (final room in membersResponse as List) {
      final roomId = room['room_id'] as String;
      final membersJson = room['members'] as List;
      final members = membersJson.map((userJson) => u.User.fromJson(userJson as Map<String, dynamic>)).toList();
      teaRoomMembers[roomId] = members;
      print(teaRoomMembers);
    }
    notifyListeners();
  }

   // ----------- SHOPS MANAGEMENT ----------------

   List<TeaRoomShop>? getShops(roomId) {
    return teaRoomShops.containsKey(roomId) ? teaRoomShops[roomId] : null;
   }

  TeaRoomShop? getShop(roomId, brandSlug) {
    final shops = getShops(roomId);
    return shops?.firstWhereOrNull((s) => s.brandSlug == brandSlug);
  }

  Future<void> loadShops(roomId) async {
    final response = await Supabase.instance.client
      .rpc('get_tea_room_shops', params: {'room_id': roomId});
    teaRoomShops[roomId] = (response as List<dynamic>).map((json) => TeaRoomShop.fromJson(json)).toList();
    notifyListeners();
  }

  void reset() {
    teaRooms.clear();
    teaRoomMembers.clear();
    teaRoomShops.clear();
    notifyListeners();
  }

  Future<void> loadFromSupabase() async { // Load in tea rooms on startup
    final supabase = Supabase.instance.client;
    final roomsResponse = await supabase.from('tea_rooms').select();
    final allTeaRooms = (roomsResponse as List).map((json) => TeaRoom.fromJson(json)).toList();
    teaRooms.clear();
    teaRooms.addAll(allTeaRooms);
    loadMembers();
  }
}