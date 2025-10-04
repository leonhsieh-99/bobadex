import 'dart:async';
import 'package:bobadex/analytics_service.dart';
import 'package:bobadex/models/brand.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/brand_details_page.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/feed_state.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/widgets/add_edit_drink_dialog.dart';
import 'package:bobadex/helpers/sortable_entry.dart';
import 'package:bobadex/models/drink_form_data.dart';
import 'package:bobadex/pages/shop_gallery_page.dart';
import 'package:bobadex/widgets/rating_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as p;
import '../models/drink.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/add_edit_shop_dialog.dart';
import '../widgets/filter_sort_bar.dart';
import '../state/drink_state.dart';
import '../config/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ShopDetailPage extends StatefulWidget{
  final String shopId;
  final String userId;

  const ShopDetailPage({
    super.key,
    required this.shopId,
    required this.userId,
  });

  @override
  State<ShopDetailPage> createState() => _ShopDetailPage();
}

class _ShopDetailPage extends State<ShopDetailPage> {
  late final String _uid;
  late final String _shopId;
  late final bool _isCurrentUser;

  late final Completer<void> _readyCompleter;
  bool _hasShownContentOnce = false;
  late Future<void> _ready = Future.value();

  final _expandedDrinkIds = <String>{};
  String _selectedSort = 'favorite-desc';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  Widget _removedPill(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red.withOpacity(.5)),
    ),
    child: const Text('Brand removed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red)),
  );

  String  getPinnedDrink(List<Drink> drinks, String id) {
    final pinned = drinks.where((d) => d.id == id).firstOrNull;
    return pinned?.name ?? '';
  }

  List<Drink> getVisibleDrinks(List<Drink> drinks) {
    List<Drink> filtered = [...drinks];

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
  void initState() {
    super.initState();
    final authId = Supabase.instance.client.auth.currentUser?.id ?? '';
    _uid = widget.userId;
    _shopId = widget.shopId;
    _isCurrentUser = _uid == authId;

    _readyCompleter = Completer<void>();
    _ready = _readyCompleter.future;

    // Defer provider notifications until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _prime(); // this can notifyListeners safely now
      } finally {
        if (!_readyCompleter.isCompleted) _readyCompleter.complete();
      }
    });
  }

  Future<void> _prime() async {
    final drinkState = context.read<DrinkState>();
    final shopMediaState = context.read<ShopMediaState>();

    await Future.wait([
      drinkState.loadForShop(_shopId, userId: _uid),
      shopMediaState.loadForShop(_shopId),
    ]);
  }

  @override
  void didUpdateWidget(covariant ShopDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shopId != widget.shopId) {
      // Also defer loads here to avoid notifying during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<DrinkState>().loadForShop(widget.shopId, force: true);
      });
      _hasShownContentOnce = false; // optional reset for a different shop
      _expandedDrinkIds.clear();
      _searchController.clear();
      _searchQuery = '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopState = context.read<ShopState>();
    final brandState = context.read<BrandState>();
    final drinkState = context.read<DrinkState>();
    final achievementState = context.read<AchievementsState>();
    final userState = context.watch<UserState>();
    final feedState = context.watch<FeedState>();
    final shopMediaState = context.watch<ShopMediaState>();
    final analytics = context.read<AnalyticsService>();

    final shop = context.watch<ShopState>().getShop(_shopId);
    final user = userState.getUser(_uid);
    final drinks = context.watch<DrinkState>().drinksFor(_shopId);

    final hasLocalData = shop != null && drinks.isNotEmpty;
    if (hasLocalData) _hasShownContentOnce = true;

    return FutureBuilder(
      future: _ready,
      builder: (context, snap) {
        final waiting = snap.connectionState == ConnectionState.waiting;
        final firstLoad = waiting && !_hasShownContentOnce;

        if (firstLoad) {
          return const ShopDetailSkeleton();
        }

        if (shop == null) {
          scheduleMicrotask(() {
            if (!mounted) return;
            Navigator.of(context).maybePop();
          });
          return const SizedBox.shrink();
        }
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Shop')),
            body: const Center(child: Text('User not found')),
          );
        }

        final refreshing = waiting && _hasShownContentOnce;

        final shopRead = shop;
        final brand    = brandState.getBrand(shopRead.brandSlug);

        final brandRemoved = (brand == null) || (brand.status == BrandStatus.retired);

        final bannerPath = shopMediaState
            .getByShop(_shopId)
            .firstWhereOrNull((m) => m.isBanner);
        final bannerUrl = bannerPath?.imageUrl;

        final pinnedDrink = (shopRead.pinnedDrinkId == null || shopRead.pinnedDrinkId!.isEmpty)
            ? ''
            : getPinnedDrink(drinks, shopRead.pinnedDrinkId!);
        final visibleDrinks = getVisibleDrinks(drinks);

        return Stack(
          children: [
            Scaffold(
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final screenHeight = constraints.maxHeight;
                  final screenWidth = constraints.maxWidth;
                  final bannerRatio = 0.3;
                  final bannerHeight = screenHeight * bannerRatio;
                  final initialSheetSize = (1.0 - bannerRatio) + 0.03; // slightly overlap image

                  void openGalleryPage(BuildContext context) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ShopGalleryPage(
                          shopMediaList: shopMediaState.getByShop(_shopId),
                          onSetBanner: (mediaId) async {
                            try {
                              await shopMediaState.setBanner(shopRead.id!, mediaId);
                              notify('New banner set', SnackType.success);
                            } catch (e) {
                              notify('Banner update failed', SnackType.error);
                            }
                            setState(() {}); // refresh
                          },
                          onDelete: (mediaId) async {
                            try {
                              await shopMediaState.removeMedia(mediaId);
                            } catch (e) {
                              if(context.mounted) {
                                debugPrint('Delete failed: $e');
                              }
                            }
                            setState(() {});
                          },
                          isCurrentUser: _isCurrentUser,
                          shopId: _shopId,
                          themeColor: user.themeSlug,
                        ),
                      ),
                    );
                  }
                  
                  return Stack(
                    children: [
                      // tappable banner
                      Stack(
                        children: [
                          SizedBox(
                            height: bannerHeight,
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: () => openGalleryPage(context),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Banner image
                                  (bannerUrl == null || bannerUrl.isEmpty)
                                      ? Container(
                                          color: Color(0xFFF5F5F5),
                                          child: const Center(
                                            child: Icon(Icons.store, size: 64, color: Colors.white70)
                                          ),
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: bannerUrl,
                                          fadeInDuration: Duration(milliseconds: 300),
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) => Container(
                                            color: Color(0xFFF5F5F5),
                                            child: const Center(child: Icon(Icons.broken_image)),
                                          ),
                                        ),
                                  // Gradient overlay at the bottom
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      height: bannerHeight * 0.35,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.22),
                                            Colors.black.withOpacity(0.38),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // ...your other widgets, icons, etc, can be added here
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: bannerHeight * 0.15,
                            right: 16,
                            child: GestureDetector(
                              onTap: () => openGalleryPage(context),
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('View all photos', style: TextStyle(fontSize: 14, color: Colors.white)),
                              )
                            )
                          ),
                          Positioned(
                            bottom: bannerHeight * 0.15,
                            left: 16,
                            child: SizedBox(
                              width: screenWidth * 0.5,
                              child: RatingPicker(
                                rating: shop.rating,
                                size: 30,
                              ),
                            ),
                          ),
                        ]
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
                                    Flexible(
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          return ConstrainedBox(
                                            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 95 / 100),
                                            child: Text(
                                              shop.name,
                                              style: const TextStyle(
                                                fontSize: 28, 
                                                fontWeight: FontWeight.bold,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              maxLines: 1,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (brandRemoved) _removedPill(context),
                                    SizedBox(width: 14),
                                    if (_isCurrentUser)
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
                                                try {
                                                  await drinkState.add(drink.toDrink(shopId: shopRead.id), shopRead.id!);
                                                  await analytics.drinkAdded(rating: drink.rating, name: drink.name);
                                                  await achievementState.checkAndUnlockDrinkAchievement(drinkState);
                                                  await achievementState.checkAndUnlockNotesAchievement(drinkState);
                                                  notify('Drink added.', SnackType.success);
                                                } catch (e) {
                                                  debugPrint('Error adding drink: $e');
                                                  notify('Error adding drink.', SnackType.error);
                                                }
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    if (!_isCurrentUser && !brandRemoved)
                                      ActionChip(
                                        label: const Text(
                                          'Visit Brand',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                        visualDensity: VisualDensity.compact,
                                        backgroundColor: Constants.getThemeColor(user.themeSlug).shade100,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BrandDetailsPage(brand: brand))),
                                      )
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.bookmark, color: Constants.heartColor, size: 24),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      flex: 8,
                                      child: Text(
                                        pinnedDrink != '' ? pinnedDrink : 'No pinned drink',
                                        style: const TextStyle(fontSize: 20),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
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
                                    controller: _searchController,
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
                                  child: (drinks.isEmpty)
                                    ? Center(child: Text('No drinks yet', style: Constants.emptyListTextStyle))
                                    : ListView.builder(
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
                                                      initiallyExpanded: drink.notes != null && drink.notes!.isNotEmpty,
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
                                                            onTap: _isCurrentUser
                                                              ? () async {
                                                                  final updated = drink.copyWith(isFavorite: !drink.isFavorite);
                                                                  try {
                                                                    await drinkState.update(updated);
                                                                    notify(updated.isFavorite ? 'Drink favorited.' : 'Drink unfavorited', SnackType.success);
                                                                  } catch (_) {
                                                                    notify('Error updating favorite status.', SnackType.error);
                                                                  }
                                                                }
                                                              : null,
                                                            child: SvgPicture.asset(
                                                              drink.isFavorite 
                                                                ? 'lib/assets/icons/heart.svg'
                                                                : 'lib/assets/icons/heart_outlined.svg',
                                                              width: 16,
                                                              height: 16,
                                                            ),
                                                          ),
                                                          if (_isCurrentUser)
                                                            PopupMenuButton<String>(
                                                              icon: const Icon(Icons.more_horiz, size: 16),
                                                              onSelected: (value) async {
                                                                final shop = shopState.getShop(widget.shopId);
                                                                switch(value) {
                                                                  case 'pin':
                                                                    final isPinned = shop?.pinnedDrinkId == drink.id;
                                                                    try {
                                                                      await shopState.update(shop!.copyWith(pinnedDrinkId: isPinned ? null : drink.id));
                                                                      notify('Pinned drink updated', SnackType.success);
                                                                    } catch (_) {
                                                                      notify('Error pinning drink', SnackType.error);
                                                                    }
                                                                    break;
                                                                  case 'edit':
                                                                    await showDialog(
                                                                      context: context,
                                                                      builder: (_) => AddOrEditDrinkDialog(
                                                                        initialData: DrinkFormData(
                                                                          name: drink.name,
                                                                          rating: drink.rating,
                                                                          notes: drink.notes,
                                                                          isFavorite: drink.isFavorite,
                                                                        ),
                                                                        onSubmit: (updatedDrink) async {
                                                                          try {
                                                                            await drinkState.update(updatedDrink.toDrink(id: drink.id, shopId: drink.shopId));
                                                                            await achievementState.checkAndUnlockDrinkAchievement(drinkState);
                                                                            await achievementState.checkAndUnlockNotesAchievement(drinkState);
                                                                            notify('Drink updated.', SnackType.success);
                                                                          } catch (_) {
                                                                            notify('Error updating drink.', SnackType.error);
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
                                                                        content: const Text('Are you sure you want to delete this drink ?'),
                                                                        actions: [
                                                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                                                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                                                        ],
                                                                      )
                                                                    );
                                                                    if (confirm == true) {
                                                                      try {
                                                                        await drinkState.remove(drink.id!);
                                                                        shopState.nullifyPinnedForDrink(drink.id!);
                                                                        notify('Drink deleted', SnackType.success);
                                                                      } catch (_) {
                                                                        notify('Error deleting drink', SnackType.error);
                                                                      }
                                                                    }
                                                                    break;
                                                                }
                                                              },
                                                              itemBuilder: (_) => [
                                                                PopupMenuItem(
                                                                  value: 'pin',
                                                                  child: Text(drink.id != shopRead.pinnedDrinkId
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
                                                          if (!_isCurrentUser)
                                                            SizedBox(width: 16,)
                                                        ],
                                                      ),
                                                      title: Row(
                                                        children: [
                                                          AnimatedRotation(
                                                            turns: _expandedDrinkIds.contains(drink.id) ? 0.25 : 0.00,
                                                            duration: const Duration(milliseconds: 200),
                                                            child: const Icon(Icons.chevron_right, size: 20),
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
                        top: 0,
                        left: 4,
                        child: SafeArea(
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black87),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                      if (_isCurrentUser)
                        Positioned(
                          top: 40,
                          right: 4,
                          child: Row(
                            children: [ 
                              GestureDetector(
                                onTap: () async {
                                  final updated = shopRead.copyWith(isFavorite: !shopRead.isFavorite);
                                  try {
                                    await shopState.update(updated);
                                    notify(updated.isFavorite ? 'Shop favorited.' : 'Shop unfavorited.', SnackType.success);
                                  } catch (_) {
                                    notify('Error updating shop favorite status.', SnackType.error);
                                  }
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (!shop.isFavorite)
                                      SvgPicture.asset(
                                        'lib/assets/icons/heart.svg',
                                        width: 24,
                                        height: 24,
                                        colorFilter: ColorFilter.mode(Colors.white.withOpacity(.3), BlendMode.srcIn),
                                      ),
                                    SvgPicture.asset(
                                      shop.isFavorite 
                                        ? 'lib/assets/icons/heart.svg'
                                        : 'lib/assets/icons/heart_outlined.svg',
                                      width: 24,
                                      height: 24,
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
                                    case 'view':
                                      if (!brandRemoved) {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => BrandDetailsPage(brand: brand)));
                                      }
                                      break;
                                    case 'edit':
                                      await showDialog(
                                        context: context,
                                        builder: (_) => AddOrEditShopDialog(
                                          shop: shopRead,
                                          brand: brand,
                                          onSubmit: (submittedShop) async {
                                            try {
                                              final persistedShop = await shopState.update(submittedShop);
                                              notify('Shop updated.', SnackType.success);
                                              return persistedShop;
                                            } catch (e) {
                                              notify('Error updating shop.', SnackType.error);
                                              rethrow;
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
                                          content: const Text('Are you sure you want to delete this shop ?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                          ],
                                        )
                                      );
                                      
                                      if (confirm == true && context.mounted) {
                                        try {
                                          // delete images first
                                          await shopMediaState.removeAllMediaForShop(widget.shopId);
                                          // delete shop
                                          await shopState.remove(widget.shopId);
                                          await feedState.removeFeedEvent(widget.shopId);
                                          notify('Shop deleted', SnackType.success);
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }
                                        } catch (e) {
                                          debugPrint("Error deleting shop");
                                          notify('Error deleting shop', SnackType.error);
                                        }
                                      }
                                      break;
                                  }
                                },
                                itemBuilder: (_) => [
                                  if (!brandRemoved) const PopupMenuItem(value: 'view', child: Text('View page')),
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
            ),
            if (refreshing)
              const Positioned(
                top: 0, left: 0, right: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ]
        );
      }
    );
  }
}

class ShopDetailSkeleton extends StatelessWidget {
  const ShopDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shop")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner / header skeleton
          Container(
            height: 250,
            color: Colors.grey[300],
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: 120,
                  height: 20,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Drinks list skeleton
          Expanded(
            child: ListView.separated(
              itemCount: 6,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.grey),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Container(
                    height: 14,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  subtitle: Container(
                    margin: const EdgeInsets.only(top: 6),
                    height: 12,
                    width: 100,
                    color: Colors.grey[200],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}