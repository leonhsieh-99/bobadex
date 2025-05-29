import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class UserCache {
  static String? username;
  static String? displayName;
  static String? profileImagePath;
  static String? bio;
  static String? themeSlug = 'grey';
  static int? gridColumns = 3;

  static final themeMap = {
    'grey': Colors.grey,
    'cyan': Colors.cyan,
    'orange': Colors.orange,
    'pink': Colors.pink,
    'red': Colors.red,
    'purple': Colors.purple,
    'green': Colors.green,
    'indigo': Colors.indigo,
    'teal': Colors.teal,
    'deepPurple': Colors.deepPurple,
    'brown': Colors.brown,
  };

  static MaterialColor get themMaterial => themeMap[themeSlug] ?? Colors.grey;

  static Future<void> loadFromSupbase() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    final profile = await supabase.from('users').select().eq('id', userId).maybeSingle();
    final settings = await supabase.from('user_settings').select().eq('user_id', userId).maybeSingle();

    username = profile?['username'];
    displayName = profile?['display_name'];
    profileImagePath = profile?['profile_image_path'];
    bio = profile?['bio'];
    themeSlug = settings?['theme_slug'] ?? 'grey';
    gridColumns = settings?['grid_columns'] ?? 3;
  }

  static Future<void> saveToSupabase() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase.from('users').update({
      'display_name': displayName,
      'username': username,
      'profile_image_path': profileImagePath,
      'bio': bio,
    }).eq('id', userId);

    await supabase.from('user_settings').update({
      'theme_slug': themeSlug,
      'grid_columns': gridColumns,
    }).eq('user_id', userId);
  }
}