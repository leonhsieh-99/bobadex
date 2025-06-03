import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/widgets/add_edit_drink_dialog.dart';
import 'package:bobadex/helpers/sortable_entry.dart';
import 'package:bobadex/models/drink_form_data.dart';
import 'package:bobadex/models/shop.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drink.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/add_edit_shop_dialog.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/filter_sort_bar.dart';
import '../state/drink_state.dart';
import '../config/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ShopDetailPage extends StatefulWidget{
  final Shop shop;

  const ShopDetailPage({
    super.key,
    required this.shop,
  });

  @override
  State<ShopDetailPage> createState() => _ShopDetailPage();
}

class _ShopDetailPage extends State<ShopDetailPage> {
  final supabase = Supabase.instance.client;
  final Set<String> _expandedDrinkIds = {};
  String _selectedSort = 'favorite-desc';
  String _searchQuery = '';
  ShopState? _shopState;
  DrinkState? _drinkState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shopState = context.read<ShopState>();
      final drinkState = context.read<DrinkState>();
      _shopState = shopState;
      _drinkState = drinkState;
    });
  }


  List<Drink> get _shopDrinks {
    return context.watch<DrinkState>().all.where((d) => d.shopId == widget.shop.id).toList();
  }

  String get pinnedDrink {
    final allDrinks = context.watch<DrinkState>().all;
    final pinned = allDrinks.where((d) => d.id == widget.shop.pinnedDrinkId).firstOrNull;
    return pinned?.name ?? '';
  }

  List<Drink> get visibleDrinks {
    List<Drink> filtered = [..._shopDrinks];

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

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopState>().getShop(widget.shop.id!)!;
    final user = context.watch<UserState>().user;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final bannerRatio = 0.3;
          final bannerHeight = screenHeight * bannerRatio;
          final initialSheetSize = (1.0 - bannerRatio) + 0.03; // slightly overlap image
          return Stack(
            children: [
              SizedBox(
                height: bannerHeight,
                width: double.infinity,
                child: (shop.imagePath == null ||  shop.imagePath!.isEmpty)
                  ? Container(
                    width: double.infinity,
                    height: 200,
                    color: Color(0xFFF5F5F5),
                    child: const Center(
                      child: Icon(Icons.store, size: 64, color: Colors.white70)
                    ),
                  )
                  : CachedNetworkImage(
                    imageUrl: shop.imageUrl,
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
              DraggableScrollableSheet(
                initialChildSize: initialSheetSize.clamp(0.5, 0.90), // prevent it from being too short/tall
                minChildSize: initialSheetSize.clamp(0.5, 0.90),
                maxChildSize: 0.90,
                builder: (context, scrollController) {
                  return Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Constants.getThemeColor(user.themeSlug).shade50,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              shop.name,
                              style: const TextStyle(
                                fontSize: 30, 
                                fontWeight: FontWeight.bold,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                            SizedBox(width: 14),
                            ActionChip(
                              label: const Text(
                                '+ Drink',
                                style: TextStyle(fontSize: 13),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Constants.getThemeColor(user.themeSlug).shade100,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              onPressed: () async {
                                await showDialog(
                                  context: context,
                                  builder: (_) => AddOrEditDrinkDialog(
                                    onSubmit: (drink) async {
                                      final response = await supabase.from('drinks').insert({
                                        'shop_id': shop.id,
                                        'user_id': supabase.auth.currentUser!.id,
                                        'name': drink.name,
                                        'rating': drink.rating,
                                        'notes': drink.notes,
                                      }).select().single();

                                      if (response != null && context.mounted) {
                                        final newDrink = Drink.fromJson(response);
                                        _drinkState?.add(newDrink);
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
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.bookmark, color: Constants.heartColor, size: 24),
                            const SizedBox(width: 8),
                            Flexible(
                              flex: 7,
                              child: Text(
                                pinnedDrink != '' ? pinnedDrink : 'No pinned drink',
                                style: const TextStyle(fontSize: 20),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (pinnedDrink != '')
                              Flexible(
                                flex: 5,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    SvgPicture.asset(
                                      'lib/assets/icons/star.svg',
                                      width: 18,
                                      height: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      shop.rating.toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            shop.notes != null && shop.notes!.isNotEmpty
                            ? shop.notes!
                            : 'No notes yet',
                            style: const TextStyle(
                              fontSize: 14, color: Colors.black,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
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
                            // controller: scrollController,
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: visibleDrinks.length,
                            itemBuilder: (context, index) {
                              final drink = visibleDrinks[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                                      child: Card(
                                        margin: EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        child: Theme(
                                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
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
                                            tilePadding: EdgeInsets.fromLTRB(6, 0, 0, 0),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                GestureDetector(
                                                  onTap: () async {
                                                    final updated = drink.copyWith(isFavorite: !drink.isFavorite);
                                                    _drinkState?.update(updated); // optimistic update
                                                    try {
                                                      await supabase
                                                        .from('drinks')
                                                        .update({'is_favorite': updated.isFavorite})
                                                        .eq('id', drink.id);
                                                    } catch (_) {
                                                      _drinkState?.update(drink); // rollback on error
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text('Failed to update favorite status.')),
                                                        );
                                                      }
                                                    }
                                                  },
                                                  child: SvgPicture.asset(
                                                    drink.isFavorite 
                                                      ? 'lib/assets/icons/heart.svg'
                                                      : 'lib/assets/icons/heart_outlined.svg',
                                                    width: 16,
                                                    height: 16,
                                                  ),
                                                ),
                                                PopupMenuButton<String>(
                                                  icon: const Icon(Icons.more_horiz, size: 16),
                                                  onSelected: (value) async {
                                                    switch(value) {
                                                      case 'pin':
                                                        final isPinned = shop.pinnedDrinkId == drink.id;
                                                        await supabase.from('shops')
                                                          .update({'pinned_drink_id': isPinned ? null : drink.id})
                                                          .eq('id', shop.id);
                                                        setState(() {
                                                          shop.pinnedDrinkId = isPinned ? null : drink.id;
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
                                                                _drinkState?.update(updated);
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
                                                          _drinkState?.remove(drink.id!);
                                                        }
                                                        break;
                                                    }
                                                  },
                                                  itemBuilder: (_) => [
                                                    PopupMenuItem(
                                                      value: 'pin',
                                                      child: Text(drink.id != shop.pinnedDrinkId
                                                        ? 'Pin'
                                                        : 'Unpin'
                                                      )
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
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  flex: 5,
                                                  child: Text(
                                                    drink.name,
                                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  flex: 2,
                                                  child:
                                                  Row(children: [
                                                SvgPicture.asset(
                                                  'lib/assets/icons/star.svg',
                                                  width: 14,
                                                  height: 14,
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  drink.rating.toStringAsFixed(1),
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
                                                ),
                                              ]
                                                  ),
                                                ),
                                              ],
                                            ),
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Text(
                                                    (drink.notes == null || drink.notes!.isEmpty)
                                                    ? 'No notes yet...'
                                                    : drink.notes!,
                                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
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
                            },
                          ),
                        ),
                      ],
                    )
                  );
                },
              ),
              Positioned(
                top: 40,
                left: 4,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                top: 40,
                right: 4,
                child: Row(
                  children: [ 
                    GestureDetector(
                      onTap: () async {
                        final updated = shop.copyWith(isFavorite: !shop.isFavorite);
                        _shopState?.update(updated); // optimistic update
                        try {
                          await supabase
                            .from('shops')
                            .update({'is_favorite': updated.isFavorite})
                            .eq('id', shop.id);
                        } catch (_) {
                          _shopState?.update(shop); // rollback on error
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update favorite status.')),
                            );
                          }
                        }
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (!shop.isFavorite)
                            SvgPicture.asset(
                              'lib/assets/icons/heart.svg',
                              width: 16,
                              height: 16,
                              colorFilter: ColorFilter.mode(Colors.white.withOpacity(.3), BlendMode.srcIn),
                            ),
                          SvgPicture.asset(
                            shop.isFavorite 
                              ? 'lib/assets/icons/heart.svg'
                              : 'lib/assets/icons/heart_outlined.svg',
                            width: 16,
                            height: 16,
                          ),
                        ],
                      )
                    ),
                    PopupMenuButton<String>(
                      icon: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const Icon(Icons.more_horiz, size: 18, color: Colors.black),
                        ]
                      ),
                      onSelected: (value) async {
                        switch(value) {
                          case 'edit':
                            await showDialog(
                              context: context,
                              builder: (_) => AddOrEditShopDialog(
                                shop: shop,
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
                                    _shopState?.update(updated);
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
                              await supabase.from('shops').delete().eq('id', shop.id);
                              _shopState?.remove(shop.id!);
                              if (context.mounted) Navigator.pop(context);
                            }
                            break;
                        }
                      },
                      itemBuilder: (_) => [
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
              ),
            ]
          );
        }
      ),
    );
  }
}
