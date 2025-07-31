import 'package:bobadex/helpers/retry_helper.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as u;

class UserState extends ChangeNotifier {
  u.User _user = u.User.empty();
  bool isLoaded = false;
  bool _hasError = false;

  u.User get user => _user;
  bool get hasError => _hasError;

  void setUser(u.User u) {
    _user = u;
    notifyListeners();
  }

  void setTheme(String slug) {
    _user.themeSlug = slug;
    notifyListeners();
  }

  Future<void> saveTheme() async {
    try {
      await Supabase.instance.client
        .from('user_settings')
        .update({'theme_slug': _user.themeSlug})
        .eq('user_id', _user.id);
      debugPrint('Theme updated');
    } catch (e) {
      debugPrint('Failed to update theme: $e');
      rethrow;
    }
  }

  void setGridLayout(int numColumns) {
    _user.gridColumns = numColumns;
    notifyListeners();
  }

  void setUseIcon() {
    _user.useIcons = !_user.useIcons;
    notifyListeners();
  }

  Future<void> saveLayout() async {
    try {
      await Supabase.instance.client
        .from('user_settings')
        .update({'grid_columns': _user.gridColumns})
        .eq('user_id', _user.id);
      await Supabase.instance.client
        .from('user_settings')
        .update({'use_icons': _user.useIcons})
        .eq('user_id', _user.id);
    } catch (e) {
      debugPrint('Failed to update grid layout');
      rethrow;
    }
  }

  Future<void> setUsername(String username) async {
    final prev = _user.username;
    setUser(_user.copyWith(username: username));

    try {
      await Supabase.instance.client
        .from('users')
        .update({ 'username': username })
        .eq('id', _user.id);
    } catch (e) {
      setUser(_user.copyWith(username: prev));
      rethrow;
    }
  }

  Future<void> setBio(String bio) async {
    final prev = _user.bio;
    setUser(_user.copyWith(bio: bio));

    try {
      await Supabase.instance.client
        .from('users')
        .update({ 'bio': bio })
        .eq('id', _user.id);
    } catch (e) {
      setUser(_user.copyWith(bio: prev));
      rethrow;
    }
  }

  Future<void> setDisplayName(String name) async {
    final prev = _user.displayName;
    setUser(_user.copyWith(displayName: name));

    try {
      await Supabase.instance.client
        .from('users')
        .update({ 'display_name': name })
        .eq('id', _user.id);
    } catch (e) {
      setUser(_user.copyWith(displayName: prev));
      rethrow;
    }
  }

  void setProfileImagePath(String path) {
    _user.profileImagePath = path;
    notifyListeners();
  }

  Future<void> setOnboarded() async {
    _user.onboarded = true;
    notifyListeners();
    try {
      await Supabase.instance.client
        .from('user_settings')
        .update({'onboarded': true})
        .eq('user_id', _user.id);
    } catch (e) {
      _user.onboarded = false;
      notifyListeners();
      debugPrint('Error setting onboarded: $e');
      rethrow;
    }
  }

  Future<bool> usernameExists(String username) async {
    try {
      return await Supabase.instance.client
        .rpc('username_exists', params: {'input_username': username});
    } catch (e) {
      debugPrint('Error checking username existence: $e');
      return false;
    }
  }

  void reset() {
    _user = u.User.empty();
    notifyListeners();
  }

  Future<void> loadFromSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      String? userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

      final results = await RetryHelper.retry(() async {
        final profile = await supabase.from('users').select().eq('id', userId).maybeSingle();
        final settings = await supabase.from('user_settings').select().eq('user_id', userId).maybeSingle();
        return [profile, settings];
      });
      final profile = results[0];
      final settings = results[1];

      if (profile != null) {
        _user = u.User.fromMap(profile, settings);
        isLoaded = true;
        notifyListeners();
        debugPrint('User state loaded');
      }
    } catch (e) {
      _hasError = true;
      isLoaded = false;
      notifyListeners();
      debugPrint('Error loading user state: $e');
    }
  }
}