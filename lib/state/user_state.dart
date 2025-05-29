import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserState extends ChangeNotifier {
  String? userId;
  String? username;
  String? displayName;
  String? themeSlug = 'grey';
  String? profileImagePath;
  String? bio;
  int gridColumns = 3;
  bool isLoaded = false;

  void setTheme(String slug) {
    themeSlug = slug;
    notifyListeners();
  }

  Future<void> saveTheme() async {
    try {
      await Supabase.instance.client
        .from('user_settings')
        .update({'theme_slug': themeSlug})
        .eq('user_id', userId);
      print('Theme updated');
    } catch (e) {
      print('Failed to update theme: $e');
    }
  }

  void setDisplayName(String name) {
    displayName = name;
    notifyListeners();
  }

  Future<void> loadFromSupabase() async {
    final supabase = Supabase.instance.client;
    userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    final profile = await supabase.from('users').select().eq('id', userId).maybeSingle();
    final settings = await supabase.from('user_settings').select().eq('user_id', userId).maybeSingle();

    username = profile?['username'];
    displayName = profile?['display_name'];
    profileImagePath = profile?['profile_image_path'];
    bio = profile?['bio'];
    themeSlug = settings?['theme_slug'] ?? 'grey';
    gridColumns = settings?['grid_columns'] ?? 3;
    
    notifyListeners();
  }
}