import 'package:bobadex/add_edit_drink_dialog.dart';
import 'package:bobadex/helpers/sortable_entry.dart';
import 'package:bobadex/models/drink_form_data.dart';
import 'package:bobadex/models/shop.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'models/drink.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_edit_shop_dialog.dart';
import 'dart:async';
import 'models/drink_cache.dart';
import 'package:shimmer/shimmer.dart';

class ShopDetailPage extends StatefulWidget{
  final Shop shop;
  final Completer<Shop?> resultCompleter;

  const ShopDetailPage({
    super.key,
    required this.shop,
    required this.resultCompleter,
  });

  @override
  State<ShopDetailPage> createState() => _ShopDetailPage();
}

class _ShopDetailPage extends State<ShopDetailPage> {
  final supabase = Supabase.instance.client;
  late Shop _shop;
  List<Drink> _drinks = [];
  final Set<String> _expandedDrinkIds = {};
  String _selectedSort = 'favorite-desc';

  @override
  void initState() {
    super.initState();
    _shop = widget.shop;
    _loadDrinks();
  }

  void _sortDrinks() {
    setState(() {
      List sortOptions = _selectedSort.split('-');
      sortEntries<Drink>(
        _drinks,
        by: sortOptions[0],
        ascending: sortOptions[1] == 'asc' ? true : false
      );
    });
  }

  void _loadDrinks() async {
    setState(() {
      _drinks = DrinkCache.all.where((d) => d.shopId == _shop.id).toList();
      _shop = _shop.copyWith(drinks: _drinks);
    });
    _sortDrinks();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!widget.resultCompleter.isCompleted) {
          widget.resultCompleter.complete(_shop);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_shop.name),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (value) async {
                switch(value) {
                  case 'favorite':
                    final updated = _shop.copyWith(isFavorite: !_shop.isFavorite);
                    await supabase.from('shops').update({'is_favorite': !updated.isFavorite}).eq('id', updated.id);
                    setState(() {
                      _shop.isFavorite = updated.isFavorite;
                    });
                    break;
                  case 'edit':
                    await showDialog(
                      context: context,
                      builder: (_) => AddOrEditShopDialog(
                        initialData: _shop,
                        onSubmit: (updatedshop) async {
                          final updatedPayload = {
                            'name': updatedshop.name,
                            'rating': updatedshop.rating,
                            'image_path': updatedshop.imagePath,
                            'notes': updatedshop.notes,
                          };
                          final response = await supabase
                            .from('shops')
                            .update(updatedPayload)
                            .eq('id', updatedshop.id)
                            .select()
                            .single();
                          
                          if (response != null && context.mounted) {
                            final updated = Shop.fromJson(response);
                            setState(() {
                              _shop = updated;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update shop.')),
                            );
                          }
                        },
                      ),
                    );
                    break;
                  case 'delete':
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete shop'),
                        content: const Text('Are you sure you want to remove this shop ?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                        ],
                      )
                    );
                    if (confirm == true) {
                      await supabase.from('shops').delete().eq('id', _shop.id);
                      if (!widget.resultCompleter.isCompleted) {
                        widget.resultCompleter.complete(null);
                        if (context.mounted) Navigator.pop(context);
                      }
                    }
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'favorite',
                  child: Text(_shop.isFavorite ? 'Unfavorite' : 'Favorite'),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ]
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.bottomLeft,
              height: 200,
              padding: const EdgeInsets.all(16),
              color: (Colors.deepPurpleAccent.withOpacity(0.4)),
              child: Row( // Banner
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _shop.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '⭐ ${_shop.rating.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '📌 ${_shop.pinnedDrink != null
                            ? _shop.pinnedDrink?.name
                            : 'No pinned drink'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _shop.notes != null && _shop.notes!.isNotEmpty
                          ? '📝 "${_shop.notes!}"'
                          : '📝 No notes yet',
                          style: const TextStyle(
                            fontSize: 14, color: Colors.black,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      ]
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (_shop.imagePath == null ||  _shop.imagePath!.isEmpty)
                          ? Container(
                            width: double.infinity,
                            height: 200,
                            color: Color(0xFFF5F5F5),
                            child: const Center(
                              child: Icon(Icons.store, size: 64, color: Colors.white70)
                            ),
                          )
                          : CachedNetworkImage(
                            imageUrl: _shop.imageUrl,
                            fadeInDuration: Duration(milliseconds: 300),
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              color: Color(0xFFF5F5F5),
                              child: const Center(child: Icon(Icons.broken_image)),
                            ),
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Color(0xFFF5F5F5),
                              highlightColor: Color(0xFFF5F5F5),
                              child: Container(
                                width: double.infinity,
                                height: 200,
                                color: Color(0xFFF5F5F5),
                              ),
                            ),
                          ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton(
                    value: _selectedSort,
                    items: const [
                      DropdownMenuItem(value: 'rating-desc', child: Text('Rating ↓')),
                      DropdownMenuItem(value: 'rating-asc', child: Text('Rating ↑')),
                      DropdownMenuItem(value: 'name-asc', child: Text('Name A–Z')),
                      DropdownMenuItem(value: 'name-desc', child: Text('Name Z–A')),
                      DropdownMenuItem(value: 'favorite-desc', child: Text('Favorites')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedSort = value!);
                      _sortDrinks();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: _drinks.length,
                itemBuilder: (context, index) {
                  final drink = _drinks[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                listTileTheme: const ListTileThemeData(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ), 
                              child: ExpansionTile(
                                initiallyExpanded: _expandedDrinkIds.contains(drink.id),
                                onExpansionChanged: (isExpanded) { 
                                  setState(() {
                                    if (isExpanded) {
                                      _expandedDrinkIds.add(drink.id ?? '');
                                    } else {
                                      _expandedDrinkIds.remove(drink.id);
                                    }
                                  });
                                },
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (drink.isFavorite) Icon(
                                      Icons.favorite,
                                      size: 20,
                                      color: Colors.redAccent,
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_horiz, size: 20),
                                      onSelected: (value) async {
                                        switch(value) {
                                          case 'pin':
                                            final isPinned = _shop.pinnedDrinkId == drink.id;
                                            await supabase.from('shops')
                                              .update({'pinned_drink_id': isPinned ? null : drink.id})
                                              .eq('id', _shop.id);
                                            setState(() {
                                              _shop.pinnedDrinkId = isPinned ? null : drink.id;
                                            });
                                            break;
                                          case 'favorite':
                                            await supabase.from('drinks').update({'is_favorite': !drink.isFavorite}).eq('id', drink.id);
                                            setState(() {
                                              _drinks = _drinks.map((d) => d.id == drink.id ? d.copyWith(isFavorite: !drink.isFavorite) : d).toList();
                                            });
                                            _sortDrinks();
                                            break;
                                          case 'edit':
                                            await showDialog(
                                              context: context,
                                              builder: (_) => AddOrEditDrinkDialog(
                                                initialData: DrinkFormData(
                                                  name: drink.name,
                                                  rating: drink.rating,
                                                  notes: drink.notes,
                                                ),
                                                onSubmit: (updatedDrink) async {
                                                  final response = await supabase
                                                    .from('drinks')
                                                    .update({
                                                      'name': updatedDrink.name,
                                                      'rating': updatedDrink.rating,
                                                      'notes': updatedDrink.notes,
                                                    })
                                                    .eq('id', drink.id)
                                                    .select()
                                                    .single();
                                                  
                                                  if (response != null && context.mounted) {
                                                    final updated = Drink.fromJson(response);
                                                    setState(() => _drinks = _drinks.map((d) => d.id == updated.id ? updated : d).toList());
                                                  } else {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Failed to update drink.')),
                                                    );
                                                  }
                                                },
                                              ),
                                            );
                                            break;
                                          case 'delete':
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Delete Drink'),
                                                content: const Text('Are you sure you want to remove this drink ?'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                                ],
                                              )
                                            );
                                            if (confirm == true) {
                                              await supabase.from('drinks').delete().eq('id', drink.id);
                                              setState(() {
                                                _drinks.removeWhere((d) => d.id == drink.id);
                                              });
                                            }
                                            break;
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          value: 'pin',
                                          child: Text(drink.id != _shop.pinnedDrinkId
                                            ? 'Pin'
                                            : 'Unpin'
                                          )
                                        ),
                                        PopupMenuItem(
                                          value: 'favorite',
                                          child: Text(drink.isFavorite ? 'Unfavorite' : 'Favorite'),
                                        ),
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                        PopupMenuItem(
                                          value: 'remove',
                                          child: Text('Remove'),
                                        ),
                                      ]
                                    ),
                                  ],
                                ),
                                title: Row(
                                  children: [
                                    AnimatedRotation(
                                      turns: _expandedDrinkIds.contains(drink.id) ? 0.25 : 0.00,
                                      duration: const Duration(milliseconds: 200),
                                      child: const Icon(Icons.chevron_right, size: 20, color: Colors.brown),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        drink.name,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text('⭐ ${drink.rating}'),
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(12, 4, 12, 12),
                                      child: Text(
                                        drink.notes ?? 'No notes yet...',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    )
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                })
            ),
          ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (_) => AddOrEditDrinkDialog(
              onSubmit: (drink) async {
                final response = await supabase.from('drinks').insert({
                  'shop_id': _shop.id,
                  'user_id': supabase.auth.currentUser!.id,
                  'name': drink.name,
                  'rating': drink.rating,
                  'notes': drink.notes,
                })
                .select()
                .single();

                if (response != null && context.mounted) {
                  final newDrink = Drink.fromJson(response);
                  setState(() => _drinks.add(newDrink));
                  _sortDrinks();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add drink.'))
                  );
                }
              },
            )
          );
        },
      ),
      )
    );
  }
}
