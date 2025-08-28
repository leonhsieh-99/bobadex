import 'package:bobadex/helpers/retry_helper.dart';
import 'package:bobadex/models/drink.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

class DrinkState extends ChangeNotifier {
  final _byShop = <String, List<Drink>>{};          // shopId -> drinks
  final _loading = <String, bool>{};                // shopId -> loading
  final _idToShop = <String, String>{};             // drinkId -> shopId
  final _lastLoadedAt = <String, DateTime>{};       // shopId -> last loaded time

  Duration cacheTtl = const Duration(minutes: 2);
  bool _hasError = false;

  //----------GETTERS-----------

  bool get hasError => _hasError;
  List<Drink> drinksFor(String shopId) => _byShop[shopId] ?? const [];
  bool isLoading(String shopId) => _loading[shopId] ?? false;

  Drink? getDrink(String? id) {
    if (id == null) return null;
    final shopId = _idToShop[id];
    if (shopId == null) return null;
    return _byShop[shopId]?.firstWhereOrNull((d) => d.id == id);
  }

  bool _isFresh(String shopId, [String? userId]) {
    if (userId != null && userId == Supabase.instance.client.auth.currentUser!.id) {
      return true;
    }

    final last = _lastLoadedAt[shopId];
    return last != null && DateTime.now().difference(last) < cacheTtl;
  }

  //----------LOADS-----------

  Future<void> loadAllForUser(String userId) async {
    try {
      final rows = await RetryHelper.retry(() => Supabase.instance.client
        .from('drinks')
        .select()
        .eq('user_id', userId)
      );

      final drinks = rows.map(Drink.fromJson).toList();

      _byShop.clear();
      _idToShop.clear();

      int drinkCount = 0;

      for (final d in drinks) {
        if (d.shopId != null && d.id != null) {
          final list = _byShop[d.shopId!] ?? <Drink>[];
          list.add(d);
          _byShop[d.shopId!] = list;
          
          _lastLoadedAt[d.shopId!] = DateTime.now();
          _idToShop[d.id!] = d.shopId!;
          drinkCount ++;
        }
      }
      _hasError = false;
      debugPrint('Loaded $drinkCount drinks');
    } catch (e) {
      debugPrint('Error loading all drinks: $e');
      _hasError = true;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadForShop(String shopId, {bool force = false, String? userId}) async {
    if (!force && _isFresh(shopId, userId)) return;
    if (isLoading(shopId)) return;
    
    _loading[shopId] = true;
    notifyListeners();
    try {
      final rows = await RetryHelper.retry(() => Supabase.instance.client
        .from('drinks')
        .select()
        .eq('shop_id', shopId)
        .order('created_at', ascending: false)
      );

      final drinks = rows.map(Drink.fromJson).toList();

      _byShop[shopId] = drinks;
      _idToShop.removeWhere((_, sid) => sid == shopId);   // rebuild index for this shop
      for (final d in drinks) {
        final id = d.id;
        if (id != null) _idToShop[id] = shopId;
      }
      _lastLoadedAt[shopId] = DateTime.now();
      _hasError = false;
    } catch (e) {
      _hasError = true;
      debugPrint('Error loading shop ($shopId): $e');
    } finally {
      _loading[shopId] = false;
      notifyListeners();
    }
  }

  //----------MUTATIONS-----------

  Future<void> update(Drink updated) async {
    final shopId = _idToShop[updated.id];
    if (shopId == null) return;

    final drinks = List<Drink>.from(_byShop[shopId] ?? const []);
    final index = drinks.indexWhere((d) => d.id == updated.id);
    if (index == -1) return;

    final temp = drinks[index]; // save prev drink state before mutation
    drinks[index] = updated;
    _byShop[shopId] = drinks;
    notifyListeners();
    try {
      await Supabase.instance.client
        .from('drinks')
        .update({
          'name': updated.name,
          'rating': updated.rating,
          'notes': updated.notes,
          'is_favorite': updated.isFavorite,
        })
        .eq('id', updated.id!);
      _lastLoadedAt[shopId] = DateTime.now();
      _hasError = false;
    } catch (e) {
      final rollback = List<Drink>.from(_byShop[shopId] ?? const []);
      if (index < rollback.length) rollback[index] = temp;
      _byShop[shopId] = rollback;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    final shopId = _idToShop[id];
    if (shopId == null) return;

    final drinks = List<Drink>.from(_byShop[shopId] ?? const []);
    final removed = drinks.firstWhereOrNull((d) => d.id == id); 

    drinks.removeWhere((d) => d.id == id);
    _byShop[shopId] = drinks;
    _idToShop.remove(id);
    notifyListeners();

    try {
      await Supabase.instance.client
        .from('drinks')
        .delete()
        .eq('id', id);

      _lastLoadedAt[shopId] = DateTime.now();
      _hasError = false;
    } catch (e) {
      debugPrint('Remove drink failed: $e');
      if (removed != null) {
        final restored = List<Drink>.from(_byShop[shopId] ?? const [])..insert(0, removed);
        _byShop[shopId] = restored;
        if (removed.id != null) _idToShop[removed.id!] = shopId;
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> add(Drink drink, String shopId) async {
    String userId = Supabase.instance.client.auth.currentUser!.id;
    final tempId = const Uuid().v4();
    final tempDrink = drink.copyWith(id: tempId); // optimistic update

    final drinks = List<Drink>.from(_byShop[shopId] ?? const []);
    drinks.insert(0, tempDrink);
    _byShop[shopId] = drinks;
    _idToShop[tempId] = shopId;
    notifyListeners();

    // save to db
    try {
      final response = await Supabase.instance.client
        .from('drinks')
        .insert({
          'shop_id': shopId,
          'user_id': userId,
          'name': drink.name,
          'rating': drink.rating,
          'notes': drink.notes,
          'is_favorite': drink.isFavorite,
        }).select().single();
      
      // Update the drink with the ID from the database
      final insertedDrink = Drink.fromJson(response);

      final index = _byShop[shopId]!.indexWhere((d) => d.id == tempId);
      if (index != -1) { // update local state with real fields
        final copy = List<Drink>.from(_byShop[shopId] ?? const []);
        copy[index] = insertedDrink;
        _byShop[shopId] = copy;

        _idToShop.remove(tempId);
        if (insertedDrink.id != null) _idToShop[insertedDrink.id!] = shopId;

        _lastLoadedAt[shopId] = DateTime.now();
        _hasError = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Insert drink failed: $e');
      final copy = List<Drink>.from(_byShop[shopId] ?? const []);
      copy.removeWhere((d) => d.id == tempId);
      _byShop[shopId] = copy;
      _idToShop.remove(tempId);
      notifyListeners();
      rethrow;
    }
  }

  //---------helpers------------
  Future<int> fetchDrinkCount(String userId) async {
    final res = await Supabase.instance.client
        .rpc('get_drink_count', params: {'uid': userId});
    return (res as int?) ?? 0;
  }


  void reset() {
    _byShop.clear();
    _loading.clear();
    _idToShop.clear();
    _lastLoadedAt.clear();
    notifyListeners();
  }
}