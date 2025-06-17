import 'package:bobadex/models/tea_room.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeaRoomState extends ChangeNotifier {
  List<TeaRoom> teaRooms = [];

  List<TeaRoom> get all => teaRooms;

  Future<void> add(TeaRoom teaRoom) async {
    teaRooms.add(teaRoom);
    notifyListeners();

    try {
      final response = await Supabase.instance.client
        .from('tea_rooms')
        .insert({
          'name': teaRoom.name,
          'description': teaRoom.description,
          'owner_id': teaRoom.ownerId,
        }).select().single();

      final index = teaRooms.indexWhere((t) => t == teaRoom);
      if (index != -1) {
        teaRooms[index] = TeaRoom.fromJson(response);
      } else {
        teaRooms.add(TeaRoom.fromJson(response));
      }
      notifyListeners();
    } catch (e) {
      print('insert failed: $e');
      teaRooms.remove(teaRoom);
      notifyListeners();
      rethrow;
    }
  }

  void reset() {
    teaRooms.clear();
    notifyListeners();
  }

  Future<void> loadFromSupabase() async {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('tea_rooms').select();
    final allTeaRooms = (response as List).map((json) => TeaRoom.fromJson(json)).toList();
    teaRooms.clear();
    teaRooms.addAll(allTeaRooms);
    notifyListeners();
  }
}