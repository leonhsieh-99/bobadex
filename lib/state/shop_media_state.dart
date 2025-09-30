import 'package:bobadex/config/constants.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/helpers/image_uploader_helper.dart';

class ShopMediaState extends ChangeNotifier {
  // ---------------- Banner cache (shopId -> banner image path) ----------------
  final Map<String, String> _bannerPathByShop = {};
  final Map<String, DateTime> _bannerLoadedAtForUser = {};
  Duration bannerTtl = const Duration(minutes: 5);

  String? getBannerPath(String shopId) => _bannerPathByShop[shopId];

  bool _bannersFreshForUser(String userId) {
    final t = _bannerLoadedAtForUser[userId];
    return t != null && DateTime.now().difference(t) < bannerTtl;
  }

  /// Fetch one banner per shop for a given user (fast; for profile grid).
  Future<void> loadBannersForUserViaRpc(String userId, {bool force = false}) async {
    if (userId.isEmpty) return;
    if (!force && _bannersFreshForUser(userId)) return;

    try {
      final rows = await Supabase.instance.client
          .rpc('shops_with_banner', params: {'p_user_id': userId}) as List<dynamic>;

      for (final r in rows.whereType<Map<String, dynamic>>()) {
        final shopId = r['shop_id'] as String;
        final path = r['banner_path'] as String?;
        if (path != null && path.isNotEmpty) {
          _bannerPathByShop[shopId] = path;
        } else {
          _bannerPathByShop.remove(shopId);
        }
      }
      _bannerLoadedAtForUser[userId] = DateTime.now();
    } catch (e) {
      debugPrint('loadBannersForUserViaRpc($userId) failed: $e');
    } finally {
      notifyListeners();
    }
  }

  void invalidateBannerForShop(String shopId, {String? userId}) {
    _bannerPathByShop.remove(shopId);
    if (userId != null) _bannerLoadedAtForUser.remove(userId);
    notifyListeners();
  }

  // ---------------- Per-shop media cache (shopId -> media list) ---------------
  final Map<String, List<ShopMedia>> _byShop = {};
  final Map<String, DateTime> _shopLoadedAt = {};
  final Set<String> _shopLoading = {};
  Duration shopTtl = const Duration(minutes: 2);

  final Map<String, String> _idToShop = {};

  List<ShopMedia> getByShop(String shopId) => _byShop[shopId] ?? const [];

  ShopMedia? getById(String id) {
    for (final list in _byShop.values) {
      final found = list.firstWhere(
        (e) => e.id == id,
        orElse: () => ShopMedia(id: '', shopId: '', userId: '', imagePath: '', visibility: 'public', isBanner: false),
      );
      if (found.id.isNotEmpty) return found;
    }
    return null;
  }

  bool _shopFresh(String shopId) {
    final t = _shopLoadedAt[shopId];
    return t != null && DateTime.now().difference(t) < shopTtl;
  }

  /// Load full media for a shop (call on detail page entry).
  Future<void> loadForShop(String shopId, {bool force = false, int? limit}) async {
    if (shopId.isEmpty) return;
    if (!force && _shopFresh(shopId)) return;
    if (_shopLoading.contains(shopId)) return;

    _shopLoading.add(shopId);
    notifyListeners();
    try {
      var query = Supabase.instance.client
          .from('shop_media')
          .select()
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

      if (limit != null) query = query.limit(limit);

      final rows = await query as List<dynamic>;

      _byShop[shopId] = rows
          .whereType<Map<String, dynamic>>()
          .map(ShopMedia.fromJson)
          .toList();

      for (final m in _byShop[shopId]!) {
        final id = m.id;
        if (id.isNotEmpty) _idToShop[id] = shopId;
      }

      _shopLoadedAt[shopId] = DateTime.now();
    } catch (e) {
      debugPrint('ShopMediaState.loadForShop($shopId) failed: $e');
    } finally {
      _shopLoading.remove(shopId);
      notifyListeners();
    }
  }

  void invalidateShop(String shopId) {
    _shopLoadedAt.remove(shopId);
    notifyListeners();
  }

  // ---------------- Mutations keep caches in sync -----------------------------
  void addPendingForShop(String shopId, ShopMedia pending) {
    final list = List<ShopMedia>.from(_byShop[shopId] ?? const []);
    list.insert(0, pending);
    _byShop[shopId] = list;
    _idToShop[pending.id] = shopId;
    notifyListeners();
  }


  void replacePendingForShop(String shopId, String pendingId, ShopMedia real) {
    final list = List<ShopMedia>.from(_byShop[shopId] ?? const []);
    final idx = list.indexWhere((m) => m.id == pendingId);
    if (idx != -1) {
      final old = list[idx];
      list[idx] = real;
      _byShop[shopId] = list;

      _idToShop.remove(old.id);
      if (real.id.isNotEmpty) {
        _idToShop[real.id] = shopId;
      }

      notifyListeners();
    }
  }

  void removePendingForShop(String shopId, String pendingId) {
    final list = List<ShopMedia>.from(_byShop[shopId] ?? const []);
    list.removeWhere((m) => m.id == pendingId);
    _byShop[shopId] = list;
    _idToShop.remove(pendingId);
    notifyListeners();
  }

  Future<ShopMedia> addMedia(ShopMedia media, {String? replacePendingId}) async {
    try {
      final response = await Supabase.instance.client
          .from('shop_media')
          .insert({
            'shop_id': media.shopId,
            'user_id': media.userId,
            'drink_id': media.drinkId,
            'image_path': media.imagePath,
            'is_banner': media.isBanner,
            'visibility': media.visibility,
            'comment': media.comment,
          })
          .select()
          .single();

      final inserted = ShopMedia.fromJson(response);
      final shopId = inserted.shopId;
      final list = List<ShopMedia>.from(_byShop[shopId] ?? const []);

      if (replacePendingId != null) {
        final idx = list.indexWhere((m) => m.id == replacePendingId);
        if (idx != -1) {
          list[idx] = inserted; // replace pending in-place
        } else {
          list.insert(0, inserted); // fallback if pending not found
        }
      } else {
        list.insert(0, inserted); // normal insert
      }

      _byShop[shopId] = list;
      _shopLoadedAt[shopId] = DateTime.now();
      _idToShop[inserted.id] = shopId;
      if (inserted.isBanner == true) {
        _bannerPathByShop[shopId] = inserted.imagePath;
      }
      notifyListeners();
      return inserted;
    } catch (e) {
      debugPrint('addMedia failed: $e');
      rethrow;
    }
  }

  Future<void> editMedia(String id, String comment, String visibility) async {
    // locate media
    String? shopId;
    int? idx;
    for (final entry in _byShop.entries) {
      final i = entry.value.indexWhere((m) => m.id == id);
      if (i != -1) {
        shopId = entry.key;
        idx = i;
        break;
      }
    }
    if (shopId == null || idx == null) return;

    final list = List<ShopMedia>.from(_byShop[shopId] ?? const []);
    final original = list[idx];
    final updated = original.copyWith(comment: comment, visibility: visibility);

    // optimistic update
    list[idx] = updated;
    _byShop[shopId] = list;
    notifyListeners();

    try {
      await Supabase.instance.client
          .from('shop_media')
          .update({'comment': comment, 'visibility': visibility})
          .eq('id', id);
    } catch (e) {
      // rollback
      list[idx] = original;
      _byShop[shopId] = list;
      notifyListeners();
      debugPrint('editMedia failed: $e');
      rethrow;
    }
  }

  Future<void> setBanner(String shopId, String mediaId) async {
    var list = List<ShopMedia>.from(_byShop[shopId] ?? const []);
    if (list.isEmpty) {
      await loadForShop(shopId, force: true);
      list = List<ShopMedia>.from(_byShop[shopId] ?? const []);
    }

    final newIdx = list.indexWhere((m) => m.id == mediaId);
    final oldIdx = list.indexWhere((m) => m.isBanner == true);
    if (newIdx == -1) return;

    final hadOld = oldIdx != -1;
    final prevOld = hadOld ? list[oldIdx] : null;
    final newMedia = list[newIdx];

    // optimistic
    if (hadOld) list[oldIdx] = prevOld!.copyWith(isBanner: false);
    list[newIdx] = newMedia.copyWith(isBanner: true);
    _byShop[shopId] = list;
    _bannerPathByShop[shopId] = newMedia.imagePath;
    notifyListeners();

    try {
      if (hadOld && prevOld!.id != mediaId) {
        await Supabase.instance.client
            .from('shop_media')
            .update({'is_banner': false})
            .eq('id', prevOld.id);
      }
      await Supabase.instance.client
          .from('shop_media')
          .update({'is_banner': true})
          .eq('id', mediaId);
    } catch (e) {
      // rollback
      if (hadOld) list[oldIdx] = prevOld!.copyWith(isBanner: true);
      list[newIdx] = newMedia.copyWith(isBanner: false);
      _byShop[shopId] = list;
      _bannerPathByShop.remove(shopId);
      notifyListeners();
      debugPrint('setBanner failed: $e');
      rethrow;
    }
  }

  Future<void> removeMedia(String id) async {
    // locate media
    String? shopId;
    int? idx;
    for (final entry in _byShop.entries) {
      final i = entry.value.indexWhere((m) => m.id == id);
      if (i != -1) {
        shopId = entry.key;
        idx = i;
        break;
      }
    }
    if (shopId == null || idx == null) return;

    final list = List<ShopMedia>.from(_byShop[shopId] ?? const []);
    final removed = list[idx];
    list.removeAt(idx);
    _byShop[shopId] = list;
    _idToShop.remove(id);
    notifyListeners();

    try {
      await Supabase.instance.client.from('shop_media').delete().eq('id', id);

      // if we removed a banner, clear banner cache for this shop
      if (removed.imagePath.isNotEmpty) {
        await ImageUploaderHelper.deleteImage(
          removed.imagePath,
          bucket: Constants.imageBucket,
          sizes: Constants.thumbSizes,
        );
      }
      if (removed.isBanner == true) {
        _bannerPathByShop.remove(shopId);
      }
    } catch (e) {
      // rollback
      list.insert(idx, removed);
      _byShop[shopId] = list;
      _idToShop[id] = shopId;
      notifyListeners();
      debugPrint('removeMedia failed: $e');
      rethrow;
    }
  }

  Future<void> removeAllMediaForShop(String shopId) async {
    final medias = List<ShopMedia>.from(_byShop[shopId] ?? const []);

    _byShop.remove(shopId);
    _shopLoadedAt.remove(shopId);
    _bannerPathByShop.remove(shopId);
    notifyListeners();


    try {
      // DB delete first
      await Supabase.instance.client
        .from('shop_media')
        .delete()
        .eq('shop_id', shopId);

      // batch Storage cleanup
      await ImageUploaderHelper.deleteManyImages(
        medias.map((m) => m.imagePath).where((p) => p.isNotEmpty),
        bucket: Constants.imageBucket,
        sizes: Constants.thumbSizes,
      );
    } catch (e) {
      debugPrint('DB delete shop_media failed: $e');
      rethrow;
    }
  }

  // on admin delete
  void removeCache(String deletedId, {String? imagePath}) {
    // Try media_id -> shopId fast path
    final shopId = _idToShop.remove(deletedId);

    if (shopId != null) {
      final list = _byShop[shopId];
      if (list != null) {
        final idx = list.indexWhere((m) => m.id == deletedId);
        if (idx != -1) {
          final wasBanner = list[idx].isBanner == true;

          list.removeAt(idx);
          if (list.isEmpty) {
            _byShop.remove(shopId);
            _shopLoadedAt.remove(shopId);
          } else {
            _byShop[shopId] = list;
          }

          // clean reverse maps
          if (wasBanner) _bannerPathByShop.remove(shopId);

          notifyListeners();
          return;
        }
      }
    }

    // Last resort: very rare slow path (guarded)
    for (final entry in _byShop.entries) {
      final list = entry.value;
      final idx = list.indexWhere((m) => m.id == deletedId || m.imagePath == imagePath);
      if (idx != -1) {
        final wasBanner = list[idx].isBanner == true;
        list.removeAt(idx);
        _byShop[entry.key] = list;
        _idToShop.remove(deletedId);
        if (wasBanner) _bannerPathByShop.remove(entry.key);
        notifyListeners();
        break;
      }
    }
  }


  void reset() {
    _bannerPathByShop.clear();
    _bannerLoadedAtForUser.clear();
    _byShop.clear();
    _shopLoadedAt.clear();
    _shopLoading.clear();
    _idToShop.clear();
    notifyListeners();
  }
}
