import 'package:bobadex/helpers/retry_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/shop.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class ShopState extends ChangeNotifier {
  final _byUser = <String, List<Shop>>{}; // userId -> shops
  final _loading = <String, bool>{}; // userId -> loading state
  final _lastLoadedAt = <String, DateTime>{}; // userId -> last load
  final _shopToUser = <String, String>{}; // shopId -> userId (fast reverse index)
  final _byId = <String, Shop>{}; // shopId -> Shop (fast lookup)

  bool _hasError = false;
  Duration cacheTtl = const Duration(minutes: 2);

  final _drinkCounts = <String, ShopDrinkCounts>{};
  Map<String, ShopDrinkCounts> get drinkCounts => _drinkCounts;

//----------GETTERS------------

  ShopDrinkCounts countsForShop(String shopId) =>
      _drinkCounts[shopId] ?? const ShopDrinkCounts();

  bool get hasError => _hasError;
  List<Shop> shopsFor(String userId) => _byUser[userId] ?? const [];
  bool isLoading(String userId) => _loading[userId] ?? false;
  
  Shop? getShop(String? shopId) => shopId == null ? null : _byId[shopId];

  Shop? getShopByBrand(String userId, String? slug) {
    if (slug == null) return null;
    return shopsFor(userId).firstWhereOrNull((s) => s.brandSlug == slug);
  }

  bool _isFresh(String userId) {
    if (userId == _currentUserId) {
      return true;
    }

    final last = _lastLoadedAt[userId];
    return last != null && DateTime.now().difference(last) < cacheTtl;
  }

  //----------DB QUERIES------------

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  Future<void> loadForUser(String userId, {bool force = false}) async {
    if (userId.isEmpty) return;
    if (!force && _isFresh(userId)) return;
    if (isLoading(userId)) return;

    _loading[userId] = true;
    notifyListeners();
    try {
      final rows = await RetryHelper.retry(() => Supabase.instance.client
        .from('shops')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false));

      final list = rows.map(Shop.fromJson).toList();
      _byUser[userId] = list;

      // rebuild indexes for this user
      _shopToUser.removeWhere((_, uid) => uid == userId);
      for (final s in list) {
        if (s.id != null) {
          _shopToUser[s.id!] = userId;
          _byId[s.id!] = s;
        }
      }

      _lastLoadedAt[userId] = DateTime.now();
      _hasError = false;
    } catch (e) {
      _hasError = true;
      debugPrint('ShopState.loadForUser($userId) failed: $e');
    } finally {
      _loading[userId] = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentUser({bool force = false}) async {
    final uid = _currentUserId;
    if (uid == null) return;
    await loadForUser(uid, force: force);
  }

    Future<void> loadDrinkCountsForCurrentUser({bool force = false}) async {
    final uid = _currentUserId;
    if (uid == null) return;
    try {
      final res = await Supabase.instance.client.rpc('drink_counts_by_shop');
      final List data =
        res is List ? res : (res == null ? const [] : [res]);
      _drinkCounts
        ..clear()
        ..addEntries(
          data.whereType<Map<String, dynamic>>().map((m) {
            final shopId = (m['shop_id'] ?? '') as String;
            return MapEntry(shopId, ShopDrinkCounts.fromMap(m));
          }),
        );
      notifyListeners();
    } catch (e) {
      debugPrint('loadDrinkCountsForCurrentUser failed: $e');
    }
  }

  //----------MUTATIONS------------

  Future<Shop> add(Shop shop) async {
    final userId = _currentUserId;
    if (userId == null) throw StateError('No signed in user');

    final tempId = const Uuid().v4();
    final tempShop = shop.copyWith(id: tempId, userId: userId);

    final list = List<Shop>.from(_byUser[userId] ?? const []);
    list.insert(0, tempShop);
    _byUser[userId] = list;
    _shopToUser[tempId] = userId;
    _byId[tempId] = tempShop;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
        .from('shops')
        .insert({
          'user_id': userId,
          'name': shop.name,
          'rating': shop.rating,
          'notes': shop.notes,
          'is_favorite': shop.isFavorite,
          'brand_slug': shop.brandSlug,
        })
        .select()
        .single();

      final insertedShop = Shop.fromJson(response);
      final index = _byUser[userId]!.indexWhere((s) => s.id == tempId);
      if (index != -1) {
        final copy = List<Shop>.from(_byUser[userId]!);
        copy[index] = insertedShop;
        _byUser[userId] = copy;
        if (insertedShop.id != null) {
          _shopToUser.remove(tempId);
          _byId.remove(tempId);
          _shopToUser[insertedShop.id!] = userId;
          _byId[insertedShop.id!] = insertedShop;
        }
        _lastLoadedAt[userId] = DateTime.now();
        _hasError = false;
        notifyListeners();
      }
      return insertedShop;
    } catch (e) {
      debugPrint('Insert shop failed: $e');
      final copy = List<Shop>.from(_byUser[userId] ?? const []);
      copy.removeWhere((s) => s.id == tempId);
      _byUser[userId] = copy;
      _shopToUser.remove(tempId);
      _byId.remove(tempId);
      notifyListeners();
      rethrow;
    }
  }

  Future<Shop> update(Shop updated, {bool touchPinned = false}) async {
    final id  = updated.id!;
    final uid = _shopToUser[id] ?? _currentUserId!;
    final current = _byUser[uid] ?? const <Shop>[];

    // Find index now
    final i0 = current.indexWhere((s) => s.id == id);
    if (i0 == -1) throw StateError('Shop not found in local state');
    final original = current[i0];

    // Optimistic replace-by-id
    final next0 = List<Shop>.from(current);
    next0[i0] = updated;
    _byUser[uid] = next0;
    _byId[id] = updated;
    notifyListeners();

    try {
      final data = <String, dynamic>{
        'name':        updated.name,
        'rating':      updated.rating,
        'is_favorite': updated.isFavorite,
        'brand_slug':  updated.brandSlug,
        'notes':       updated.notes,
      };

      // send pinned only if changed
      final pinnedChanged = updated.pinnedDrinkId != original.pinnedDrinkId;
      if (pinnedChanged) {
        data['pinned_drink_id'] =
            (updated.pinnedDrinkId == null || updated.pinnedDrinkId!.isEmpty)
                ? null
                : updated.pinnedDrinkId;
      }

      final res = await Supabase.instance.client
          .from('shops').update(data).eq('id', id).select().single();

      final persisted = Shop.fromJson(res);

      // 🔐 Recompute index now (list may have re-ordered)
      final nowList = _byUser[uid] ?? const <Shop>[];
      final iNow = nowList.indexWhere((s) => s.id == id);
      if (iNow != -1) {
        final next = List<Shop>.from(nowList);
        next[iNow] = persisted;
        _byUser[uid] = next;
      }
      _byId[id] = persisted;
      notifyListeners();
      return persisted;
    } catch (e) {
      // Recompute index again for rollback
      final nowList = _byUser[uid] ?? const <Shop>[];
      final iNow = nowList.indexWhere((s) => s.id == id);
      if (iNow != -1) {
        final next = List<Shop>.from(nowList);
        next[iNow] = original;
        _byUser[uid] = next;
      }
      _byId[id] = original;
      notifyListeners();
      rethrow;
    }
  }


  Future<void> remove(String id) async {
    final uid = _shopToUser[id] ?? _currentUserId;
    if (uid == null) throw StateError('No user context for shop');

    final list = List<Shop>.from(_byUser[uid] ?? const []);
    final removed = list.firstWhereOrNull((s) => s.id == id);

    list.removeWhere((s) => s.id == id);
    _byUser[uid] = list;
    _byId.remove(id);
    _shopToUser.remove(id);
    notifyListeners();

    try {
      await Supabase.instance.client.from('shops').delete().eq('id', id);
      await Supabase.instance.client
          .from('feed_events')
          .delete()
          .eq('object_id', id)
          .eq('event_type', 'shop_add');

      _lastLoadedAt[uid] = DateTime.now();
      _hasError = false;
    } catch (e) {
      // rollback
      if (removed != null) {
        final copy = List<Shop>.from(_byUser[uid] ?? const [])..insert(0, removed);
        _byUser[uid] = copy;
        _byId[id] = removed;
        _shopToUser[id] = uid;
        notifyListeners();
      }
      debugPrint('Remove shop failed: $e');
      rethrow;
    }
  }

  void replace(String oldId, Shop newShop) {
    final uid = newShop.userId;
    final list = List<Shop>.from(_byUser[uid] ?? const []);
    final index = list.indexWhere((s) => s.id == oldId);
    if (index != -1) {
      list[index] = newShop;
    } else {
      list.insert(0, newShop);
    }
    _byUser[uid] = list;

    if (oldId != newShop.id) {
      _byId.remove(oldId);
      _shopToUser.remove(oldId);
    }
    if (newShop.id != null) {
      _byId[newShop.id!] = newShop;
      _shopToUser[newShop.id!] = uid;
    }
    notifyListeners();
  }
  
  // --------------HELPERS--------------

  Future<List<Shop>> fetchUserShops(String userId, {bool force = false}) async {
    await loadForUser(userId, force: force);
    return shopsFor(userId);
  }

  List<Shop> shopsForCurrentUser() {
    final uid = _currentUserId;
    if (uid == null) return const [];
    return _byUser[uid] ?? const [];
  }

  void nullifyPinnedForDrink(String drinkId) {
    _byId.updateAll((_, s) => s.pinnedDrinkId == drinkId ? s.copyWith(pinnedDrinkId: null) : s);
    _byUser.updateAll((_, list) => [
      for (final s in list) s.pinnedDrinkId == drinkId ? s.copyWith(pinnedDrinkId: null) : s
    ]);
    notifyListeners();
  }

  void reset() {
    _byUser.clear();
    _loading.clear();
    _lastLoadedAt.clear();
    _shopToUser.clear();
    _byId.clear();
    _hasError = false;
    notifyListeners();
  }
}

// --------HELPER CLASS----------
class ShopDrinkCounts {
  final int total;
  final int notes;
  final int matcha;
  const ShopDrinkCounts({this.total = 0, this.notes = 0, this.matcha = 0});
  factory ShopDrinkCounts.fromMap(Map<String, dynamic> m) => ShopDrinkCounts(
    total: (m['total'] ?? 0) is num ? (m['total'] as num).toInt() : 0,
    notes: (m['notes'] ?? 0) is num ? (m['notes'] as num).toInt() : 0,
    matcha: (m['matcha'] ?? 0) is num ? (m['matcha'] as num).toInt() : 0,
  );
}