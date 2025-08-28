import 'package:bobadex/helpers/retry_helper.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as u;

class UserState extends ChangeNotifier {
  final _byId = <String, u.User>{};            // userId -> User model (includes settings)
  final _loading = <String, bool>{};           // userId -> loading
  final _lastLoadedAt = <String, DateTime>{};  // userId -> last load time

  Duration cacheTtl = const Duration(minutes: 2);
  bool isLoaded = false;
  bool _hasError = false;

  // ---------- GETTERS -------------
  bool get hasError => _hasError;
  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  u.User get current => (_currentUserId != null)
    ? (_byId[_currentUserId!] ?? u.User.empty())
    : u.User.empty();

  bool isLoading(String userId) => _loading[userId] ?? false;

  u.User? getUser(String? id) => id == null ? null : _byId[id];

  bool _isFresh(String userId) {
    final t = _lastLoadedAt[userId];
    return t != null && DateTime.now().difference(t) < cacheTtl;
  }

  // ---------LOADS-------------
  Future<void> loadCurrent({bool force = false}) async {
    final id = _currentUserId;
    if (id == null) return;
      await loadUser(id, force: force);
  }

  Future<void> loadUser(String userId, {bool force = false}) async {
    if (userId.isEmpty) return;
    if (!force && _isFresh(userId)) return;
    if (isLoading(userId)) return;

    _loading[userId] = true;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;
      final result = await RetryHelper.retry(() async {
        final profileF = supabase
            .from('users')
            .select()
            .eq('id', userId)
            .single();

        final settingsF = supabase
            .from('user_settings')
            .select()
            .eq('user_id', userId)
            .single();

        final profile = await profileF;
        Map<String, dynamic>? settings;
        try {
          settings = await settingsF;
        } catch (_) {
          // If no settings row yet, leave null; your model can default.
          settings = null;
        }
        return [profile, settings];
      });

      final profile = result[0] as Map<String, dynamic>;
      final settings = result[1] as Map<String, dynamic>;

      final user = u.User.fromMap(profile, settings);
      _byId[userId] = user;
      _lastLoadedAt[userId] = DateTime.now();
      _hasError = false;
    } catch (e) {
      _hasError = true;
      debugPrint('UserState.loadUser($userId) failed: $e');
    } finally {
      _loading[userId] = false;
      notifyListeners();
    }
  }

  //-------SETTERS---------

  void setUser(u.User user) {
    if (user.id.isEmpty) return;
    _byId[user.id] = user;
    notifyListeners();
  }

  void setTheme(String slug) {
    final id = _currentUserId;
    if (id == null) return;
    final cur = _byId[id] ?? u.User.empty().copyWith(id: id);
    _byId[id] = cur.copyWith(themeSlug: slug);
    notifyListeners();
  }


  void setGridLayout(int numColumns) {
    final id = _currentUserId;
    if (id == null) return;
    final cur = _byId[id] ?? u.User.empty().copyWith(id: id);
    _byId[id] = cur.copyWith(gridColumns: numColumns);
    notifyListeners();
  }

  void toggleUseIcons() {
    final id = _currentUserId;
    if (id == null) return;
    final cur = _byId[id] ?? u.User.empty().copyWith(id: id);
    _byId[id] = cur.copyWith(useIcons: !cur.useIcons);
    notifyListeners();
  }

  void setProfileImagePath(String path) {
    final id = _currentUserId;
    if (id == null) return;
    final cur = _byId[id] ?? u.User.empty().copyWith(id: id);
    _byId[id] = cur.copyWith(profileImagePath: path);
    notifyListeners();
  }

  //---------SAVES (WRITE TO DB)-----------

  Future<void> saveTheme() async {
    final id = _currentUserId;
    if (id == null) return;
    final cur = _byId[id] ?? u.User.empty().copyWith(id: id);

    try {
      await Supabase.instance.client
          .from('user_settings')
          .update({'theme_slug': cur.themeSlug})
          .eq('user_id', id);
      _lastLoadedAt[id] = DateTime.now();
      debugPrint('Theme updated');
    } catch (e) {
      debugPrint('Failed to update theme: $e');
      rethrow;
    }
  }

  Future<void> saveLayout() async {
    final id = _currentUserId;
    if (id == null) return;
    final cur = _byId[id] ?? u.User.empty().copyWith(id: id);

    try {
      await Supabase.instance.client
          .from('user_settings')
          .update({
            'grid_columns': cur.gridColumns,
            'use_icons': cur.useIcons,
          })
          .eq('user_id', id);
      _lastLoadedAt[id] = DateTime.now();
    } catch (e) {
      debugPrint('Failed to update layout: $e');
      rethrow;
    }
  }

  Future<void> setOnboarded() async {
    final id = _currentUserId;
    if (id == null) return;
    final cur = _byId[id] ?? u.User.empty().copyWith(id: id);

    _byId[id] = cur.copyWith(onboarded: true);
    notifyListeners();

    try {
      await Supabase.instance.client
          .from('user_settings')
          .update({'onboarded': true})
          .eq('user_id', id);
      _lastLoadedAt[id] = DateTime.now();
    } catch (e) {
      _byId[id] = cur.copyWith(onboarded: false); // rollback
      notifyListeners();
      debugPrint('Error setting onboarded: $e');
      rethrow;
    }
  }

  // -------rest of the mutations----------

  Future<void> setUsername(String username) async {
    final id = _currentUserId;
    if (id == null) throw StateError('No signed-in user');
    final prev = _byId[id] ?? u.User.empty().copyWith(id: id);
    _byId[id] = prev.copyWith(username: username);
    notifyListeners();
    try {
      await Supabase.instance.client
          .from('users')
          .update({'username': username})
          .eq('id', id);
      _lastLoadedAt[id] = DateTime.now();
    } catch (e) {
      _byId[id] = prev; // rollback
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setBio(String bio) async {
    final id = _currentUserId;
    if (id == null) throw StateError('No signed-in user');
    final prev = _byId[id] ?? u.User.empty().copyWith(id: id);
    _byId[id] = prev.copyWith(bio: bio);
    notifyListeners();
    try {
      await Supabase.instance.client
          .from('users')
          .update({'bio': bio})
          .eq('id', id);
      _lastLoadedAt[id] = DateTime.now();
    } catch (e) {
      _byId[id] = prev; // rollback
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setDisplayName(String name) async {
    final id = _currentUserId;
    if (id == null) throw StateError('No signed-in user');
    final prev = _byId[id] ?? u.User.empty().copyWith(id: id);
    _byId[id] = prev.copyWith(displayName: name);
    notifyListeners();
    try {
      await Supabase.instance.client
          .from('users')
          .update({'display_name': name})
          .eq('id', id);
      _lastLoadedAt[id] = DateTime.now();
    } catch (e) {
      _byId[id] = prev; // rollback
      notifyListeners();
      rethrow;
    }
  }

  //---------utils-------------

  Future<bool> usernameExists(String username) async {
    try {
      final res = await Supabase.instance.client
          .rpc('username_exists', params: {'input_username': username});
      return (res == true);
    } catch (e) {
      debugPrint('Error checking username existence: $e');
      return false;
    }
  }

  void reset() {
    _byId.clear();
    _loading.clear();
    _lastLoadedAt.clear();
    _hasError = false;
    notifyListeners();
  }
}