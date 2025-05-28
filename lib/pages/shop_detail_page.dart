import 'package:bobadex/widgets/add_edit_drink_dialog.dart';
import 'package:bobadex/helpers/sortable_entry.dart';
import 'package:bobadex/models/drink_form_data.dart';
import 'package:bobadex/models/shop.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/drink.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/add_edit_shop_dialog.dart';
import 'dart:async';
import '../models/drink_cache.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/filter_sort_bar.dart';

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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _shop = widget.shop;
    _loadDrinks();
  }

  List<Drink> get visibleDrinks {
    List<Drink> filtered = [..._drinks];

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((d) =>
        d.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    List options = _selectedSort.split('-');
    sortEntries(
      filtered,
      by: options[0],
      ascending: options[1] == 'asc',
    );

    return filtered;
  }

  void _loadDrinks() async {
    setState(() {
      _drinks = DrinkCache.all.where((d) => d.shopId == _shop.id).toList();
      _shop = _shop.copyWith(drinks: _drinks);
    });
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
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  alignment: Alignment.bottomLeft,
                  height: 260,
                  padding: const EdgeInsets.fromLTRB(12, 50, 12, 12),
                  color: (Colors.deepPurpleAccent.withOpacity(0.4)),
                  child: Row( // Banner
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _shop.name,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  onSelected: (value) async {
                                    switch(value) {
                                      case 'favorite':
                                        await supabase.from('shops').update({'is_favorite': !_shop.isFavorite}).eq('id', _shop.id);
                                        setState(() {
                                          _shop.isFavorite = !_shop.isFavorite;
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
                                ActionChip(
                                  label: const Text(
                                    '+ Drink',
                                    style: TextStyle(
                                      color: Colors.deepPurple,
                                      fontSize: 13,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    side: const BorderSide(color: Colors.deepPurple),
                                  ),
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
                                          }).select().single();

                                          if (response != null && context.mounted) {
                                            final newDrink = Drink.fromJson(response);
                                            setState(() {
                                              _drinks.add(newDrink);
                                              DrinkCache.add(newDrink);
                                            });
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Failed to add drink.')),
                                            );
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ]
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
                Positioned(
                  top: 40,
                  left: 12,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () {
                      if (!widget.resultCompleter.isCompleted) {
                        widget.resultCompleter.complete(_shop);
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ]
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: FilterSortBar(
                sortOptions: [
                  SortOption('favorite', Icons.favorite),
                  SortOption('rating', Icons.star),
                  SortOption('name', Icons.sort_by_alpha),
                  SortOption('createdAt', Icons.access_time),
                ],
                onSearchChanged: (query) {
                  setState(() => _searchQuery = query);
                },
                onSortSelected: (sortKey) {
                  setState(() => _selectedSort = sortKey);
                }
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: visibleDrinks.length,
                itemBuilder: (context, index) {
                  final drink = visibleDrinks[index];
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
                                          case 'remove':
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
                                                DrinkCache.remove(drink.id!);
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
      )
    );
  }
}
