import 'dart:async';
import 'package:bobadex/analytics_service.dart';
import 'package:bobadex/models/brand.dart';
import 'package:bobadex/models/shop.dart';
import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/models/user.dart' as u;
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
import 'package:bobadex/state/drink_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drink.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/add_edit_shop_dialog.dart';
import '../widgets/filter_sort_bar.dart';
import 'package:bobadex/ui/components/boba_button.dart';
import 'package:bobadex/ui/components/boba_card.dart';
import 'package:bobadex/ui/components/drink_row.dart';
import 'package:bobadex/ui/components/empty_state.dart';
import 'package:bobadex/ui/components/rating_text.dart';
import 'package:bobadex/ui/components/section_header.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/widgets/brand_mark.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ShopDetailPage extends StatefulWidget {
  final String shopId;
  final String userId;

  const ShopDetailPage({super.key, required this.shopId, required this.userId});

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
  bool _shopNotesExpanded = false;

  Widget _removedPill(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: ctx.boba.danger.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: ctx.boba.danger.withValues(alpha: .5)),
    ),
    child: Text(
      'Brand removed',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: ctx.boba.danger,
      ),
    ),
  );

  String getPinnedDrink(List<Drink> drinks, String id) {
    final pinned = drinks.where((d) => d.id == id).firstOrNull;
    return pinned?.name ?? '';
  }

  List<Drink> getVisibleDrinks(List<Drink> drinks) {
    List<Drink> filtered = [...drinks];

    if (_searchQuery.isNotEmpty && drinks.length > 5) {
      filtered = filtered
          .where(
            (d) => d.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    List options = _selectedSort.split('-');
    sortEntries(filtered, by: options[0], ascending: options[1] == 'asc');

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

  String _collectedCaption(Shop shop, int drinkCount) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final drinks = drinkCount == 1 ? '1 drink' : '$drinkCount drinks';
    final created = shop.createdAt;
    if (created.millisecondsSinceEpoch <= 0) return drinks;
    return 'Collected ${months[created.month - 1]} ${created.year} · $drinks';
  }

  Future<void> _promptAddDrink({
    required DrinkState drinkState,
    required AchievementsState achievementState,
    required AnalyticsService analytics,
    required Shop shop,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => AddOrEditDrinkDialog(
        onSubmit: (drink) async {
          try {
            await drinkState.add(drink.toDrink(shopId: shop.id), shop.id!);
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
  }

  Future<void> _handleDrinkAction({
    required String value,
    required Drink drink,
    required Shop shop,
    required DrinkState drinkState,
    required ShopState shopState,
    required AchievementsState achievementState,
  }) async {
    switch (value) {
      case 'pin':
        final isPinned = shop.pinnedDrinkId == drink.id;
        try {
          await shopState.update(
            shop.copyWith(pinnedDrinkId: isPinned ? '' : drink.id),
          );
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
                await drinkState.update(
                  updatedDrink.toDrink(id: drink.id, shopId: drink.shopId),
                );
                await achievementState.checkAndUnlockDrinkAchievement(
                  drinkState,
                );
                await achievementState.checkAndUnlockNotesAchievement(
                  drinkState,
                );
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
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
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
  }

  Widget _buildDrinkSheet({
    required BuildContext context,
    required Shop shop,
    required Brand? brand,
    required bool brandRemoved,
    required List<Drink> drinks,
    required List<Drink> visibleDrinks,
    required String pinnedDrink,
    required DrinkState drinkState,
    required ShopState shopState,
    required AchievementsState achievementState,
    required AnalyticsService analytics,
  }) {
    final tokens = context.boba;
    final shopNotes = shop.notes?.trim() ?? '';
    final showFilters = drinks.length > 5;
    final pinned = drinks.where((d) => d.id == shop.pinnedDrinkId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrandMark(
              name: brand?.display ?? shop.name,
              slug: shop.brandSlug,
              iconPath: brand?.iconPath,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shop.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      if (brandRemoved) ...[
                        const SizedBox(width: 8),
                        _removedPill(context),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _collectedCaption(shop, drinks.length),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: tokens.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            RatingText(value: shop.rating, size: RatingTextSize.large),
          ],
        ),
        if (!_isCurrentUser && !brandRemoved) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: BobaButton(
              label: 'Visit brand',
              size: BobaButtonSize.small,
              variant: BobaButtonVariant.secondary,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BrandDetailsPage(brand: brand!),
                ),
              ),
            ),
          ),
        ],
        if (pinned != null && pinnedDrink.isNotEmpty) ...[
          const SizedBox(height: 12),
          BobaCard(
            variant: BobaCardVariant.inset,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.bookmark_rounded, size: 18, color: tokens.heart),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pinned.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                RatingText(value: pinned.rating, size: RatingTextSize.small),
              ],
            ),
          ),
        ],
        if (shopNotes.isNotEmpty) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: shopNotes.length > 120 || shopNotes.contains('\n')
                ? () => setState(() => _shopNotesExpanded = !_shopNotesExpanded)
                : null,
            child: Text(
              shopNotes,
              maxLines: _shopNotesExpanded ? null : 3,
              overflow: _shopNotesExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
        SectionHeader(
          title: drinks.isEmpty ? 'Drinks' : 'Drinks (${drinks.length})',
          padding: const EdgeInsets.only(top: 0, bottom: 4),
          trailing: _isCurrentUser
              ? BobaButton(
                  label: '+ Drink',
                  size: BobaButtonSize.small,
                  variant: BobaButtonVariant.secondary,
                  onPressed: () => _promptAddDrink(
                    drinkState: drinkState,
                    achievementState: achievementState,
                    analytics: analytics,
                    shop: shop,
                  ),
                )
              : null,
        ),
        if (showFilters)
          FilterSortBar(
            controller: _searchController,
            searchHint: 'Search drinks',
            searchHeight: 40,
            padding: const EdgeInsets.only(bottom: 4),
            sortOptions: [
              SortOption('favorite', Icons.favorite, label: 'Favorites'),
              SortOption('rating', Icons.star, label: 'Rating'),
              SortOption('name', Icons.sort_by_alpha, label: 'Name'),
              SortOption('createdAt', Icons.access_time, label: 'Recent'),
            ],
            onSearchChanged: (query) => setState(() => _searchQuery = query),
            onSortSelected: (sortKey) =>
                setState(() => _selectedSort = sortKey),
          ),
        Expanded(
          child: drinks.isEmpty
              ? EmptyState(
                  title: 'No drinks logged yet',
                  body: _isCurrentUser
                      ? 'Add the drinks you actually order here.'
                      : null,
                  action: _isCurrentUser
                      ? BobaButton(
                          label: 'Log your first drink',
                          onPressed: () => _promptAddDrink(
                            drinkState: drinkState,
                            achievementState: achievementState,
                            analytics: analytics,
                            shop: shop,
                          ),
                        )
                      : null,
                )
              : visibleDrinks.isEmpty
              ? Center(
                  child: Text(
                    'Nothing matches that search',
                    style: context.bobaText.empty,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: visibleDrinks.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: tokens.outline),
                  itemBuilder: (context, index) {
                    final drink = visibleDrinks[index];
                    final id = drink.id ?? '';
                    return DrinkRow(
                      drink: drink,
                      expanded: _expandedDrinkIds.contains(id),
                      isPinned: drink.id == shop.pinnedDrinkId,
                      isOwner: _isCurrentUser,
                      onToggleExpand: () {
                        setState(() {
                          if (_expandedDrinkIds.contains(id)) {
                            _expandedDrinkIds.remove(id);
                          } else {
                            _expandedDrinkIds.add(id);
                          }
                        });
                      },
                      onFavorite: () async {
                        final updated = drink.copyWith(
                          isFavorite: !drink.isFavorite,
                        );
                        try {
                          await drinkState.update(updated);
                          notify(
                            updated.isFavorite
                                ? 'Drink favorited.'
                                : 'Drink unfavorited',
                            SnackType.success,
                          );
                        } catch (_) {
                          notify(
                            'Error updating favorite status.',
                            SnackType.error,
                          );
                        }
                      },
                      onMenuSelected: (value) => _handleDrinkAction(
                        value: value,
                        drink: drink,
                        shop: shop,
                        drinkState: drinkState,
                        shopState: shopState,
                        achievementState: achievementState,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopState = context.read<ShopState>();
    final brandState = context.read<BrandState>();
    final drinkState = context.read<DrinkState>();
    final achievementState = context.read<AchievementsState>();
    final feedState = context.read<FeedState>();
    final shopMediaState = context.read<ShopMediaState>();
    final analytics = context.read<AnalyticsService>();

    final shop = context.select<ShopState, Shop?>((s) => s.getShop(_shopId));
    final user = context.select<UserState, u.User?>((s) => s.getUser(_uid));
    final drinks = context.select<DrinkState, List<Drink>>(
      (s) => s.drinksFor(_shopId),
    );
    final shopMediaList = context.select<ShopMediaState, List<ShopMedia>>(
      (s) => s.getByShop(_shopId),
    );

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
        final brand = brandState.getBrand(shopRead.brandSlug);

        final brandRemoved = (brand == null) || !brand.status.isActive;

        final bannerPath = shopMediaList.firstWhereOrNull((m) => m.isBanner);
        final bannerUrl = bannerPath?.imageUrl;

        final pinnedDrink =
            (shopRead.pinnedDrinkId == null || shopRead.pinnedDrinkId!.isEmpty)
            ? ''
            : getPinnedDrink(drinks, shopRead.pinnedDrinkId!);
        final visibleDrinks = getVisibleDrinks(drinks);

        return Stack(
          children: [
            Scaffold(
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final screenHeight = constraints.maxHeight;
                  final bannerRatio = 0.3;
                  final bannerHeight = screenHeight * bannerRatio;
                  final initialSheetSize =
                      (1.0 - bannerRatio) + 0.03; // slightly overlap image

                  void openGalleryPage(BuildContext context) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ShopGalleryPage(
                          shopMediaList: shopMediaList,
                          onSetBanner: (mediaId) async {
                            try {
                              await shopMediaState.setBanner(
                                shopRead.id!,
                                mediaId,
                              );
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
                              if (context.mounted) {
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
                                      ? ColoredBox(
                                          color: context.boba.accentSoft,
                                          child: Center(
                                            child: BrandMark(
                                              name: brand?.display ?? shop.name,
                                              slug: shop.brandSlug,
                                              iconPath: brand?.iconPath,
                                              size: 96,
                                              circular: true,
                                            ),
                                          ),
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: bannerUrl,
                                          fadeInDuration: Duration(
                                            milliseconds: 300,
                                          ),
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) =>
                                              Container(
                                                color: context.boba.surfaceAlt,
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                  ),
                                                ),
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
                                            context.boba.imageScrim.withValues(
                                              alpha: 0.22,
                                            ),
                                            context.boba.imageScrim.withValues(
                                              alpha: 0.38,
                                            ),
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
                          if (_isCurrentUser || shopMediaList.isNotEmpty)
                            Positioned(
                              bottom: bannerHeight * 0.15,
                              right: 16,
                              child: GestureDetector(
                                onTap: () => openGalleryPage(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.boba.imageScrim.withValues(
                                      alpha: 0.3,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    (bannerUrl == null || bannerUrl.isEmpty) &&
                                            _isCurrentUser
                                        ? 'Add a photo'
                                        : 'View all photos',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: context.boba.onImage,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      DraggableScrollableSheet(
                        initialChildSize: initialSheetSize.clamp(
                          0.5,
                          0.90,
                        ), // prevent it from being too short/tall
                        minChildSize: initialSheetSize.clamp(0.5, 0.90),
                        maxChildSize: 0.90,
                        builder: (context, scrollController) {
                          return Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: context.boba.surface,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: _buildDrinkSheet(
                              context: context,
                              shop: shopRead,
                              brand: brand,
                              brandRemoved: brandRemoved,
                              drinks: drinks,
                              visibleDrinks: visibleDrinks,
                              pinnedDrink: pinnedDrink,
                              drinkState: drinkState,
                              shopState: shopState,
                              achievementState: achievementState,
                              analytics: analytics,
                            ),
                          );
                        },
                      ),
                      Positioned(
                        top: 0,
                        left: 4,
                        child: SafeArea(
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: context.boba.ink,
                            ),
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
                                  final updated = shopRead.copyWith(
                                    isFavorite: !shopRead.isFavorite,
                                  );
                                  try {
                                    await shopState.update(updated);
                                    notify(
                                      updated.isFavorite
                                          ? 'Shop favorited.'
                                          : 'Shop unfavorited.',
                                      SnackType.success,
                                    );
                                  } catch (_) {
                                    notify(
                                      'Error updating shop favorite status.',
                                      SnackType.error,
                                    );
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
                                        colorFilter: ColorFilter.mode(
                                          context.boba.onImage.withValues(
                                            alpha: .3,
                                          ),
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    SvgPicture.asset(
                                      shop.isFavorite
                                          ? 'lib/assets/icons/heart.svg'
                                          : 'lib/assets/icons/heart_outlined.svg',
                                      width: 24,
                                      height: 24,
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: context.boba.onImage.withValues(
                                          alpha: .3,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    Icon(
                                      Icons.more_horiz,
                                      size: 18,
                                      color: context.boba.ink,
                                    ),
                                  ],
                                ),
                                onSelected: (value) async {
                                  switch (value) {
                                    case 'view':
                                      if (!brandRemoved) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                BrandDetailsPage(brand: brand),
                                          ),
                                        );
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
                                              final persistedShop =
                                                  await shopState.update(
                                                    submittedShop,
                                                  );
                                              notify(
                                                'Shop updated.',
                                                SnackType.success,
                                              );
                                              return persistedShop;
                                            } catch (e) {
                                              notify(
                                                'Error updating shop.',
                                                SnackType.error,
                                              );
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
                                          content: const Text(
                                            'Are you sure you want to delete this shop ?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true && context.mounted) {
                                        try {
                                          // delete images first
                                          await shopMediaState
                                              .removeAllMediaForShop(
                                                widget.shopId,
                                              );
                                          // delete shop
                                          await shopState.remove(widget.shopId);
                                          await feedState.removeFeedEvent(
                                            widget.shopId,
                                          );
                                          notify(
                                            'Shop deleted',
                                            SnackType.success,
                                          );
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }
                                        } catch (e) {
                                          debugPrint("Error deleting shop");
                                          notify(
                                            'Error deleting shop',
                                            SnackType.error,
                                          );
                                        }
                                      }
                                      break;
                                  }
                                },
                                itemBuilder: (_) => [
                                  if (!brandRemoved)
                                    const PopupMenuItem(
                                      value: 'view',
                                      child: Text('View page'),
                                    ),
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            if (refreshing)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        );
      },
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
            color: context.boba.surfaceAlt,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: 120,
                  height: 20,
                  color: context.boba.outline,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Drinks list skeleton
          Expanded(
            child: ListView.separated(
              itemCount: 6,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: context.boba.outline),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.boba.outline,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Container(
                    height: 14,
                    width: double.infinity,
                    color: context.boba.outline,
                  ),
                  subtitle: Container(
                    margin: const EdgeInsets.only(top: 6),
                    height: 12,
                    width: 100,
                    color: context.boba.surfaceAlt,
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
