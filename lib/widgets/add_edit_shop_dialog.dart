import 'package:bobadex/analytics_service.dart';
import 'package:bobadex/config/constants.dart';
import 'package:bobadex/models/drink_form_data.dart';
import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/drink_state.dart';
import 'package:bobadex/state/feed_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/widgets/image_widgets/fullscreen_image_viewer.dart';
import 'package:bobadex/widgets/image_widgets/multiselect_image_picker.dart';
import 'package:bobadex/ui/components/boba_button.dart';
import 'package:bobadex/ui/components/boba_chip.dart';
import 'package:bobadex/ui/components/boba_sheet.dart';
import 'package:bobadex/ui/components/rating_text.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:bobadex/widgets/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/shop.dart';
import '../models/brand.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rating_picker.dart';
import '../helpers/image_uploader_helper.dart';

class AddOrEditShopDialog extends StatefulWidget {
  final Shop? shop;
  final Future<Shop> Function(Shop) onSubmit;
  final Brand? brand;
  final ScrollController? scrollController;

  const AddOrEditShopDialog({
    super.key,
    this.shop,
    required this.onSubmit,
    this.brand,
    this.scrollController,
  });

  static Future<void> show(
    BuildContext context, {
    Shop? shop,
    required Future<Shop> Function(Shop) onSubmit,
    Brand? brand,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.boba.surface,
      builder: (context) {
        final keyboard = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return BobaSheet(
                showGrabber: true,
                expand: true,
                padding: const EdgeInsets.only(top: BobaSpace.x3),
                child: AddOrEditShopDialog(
                  shop: shop,
                  onSubmit: onSubmit,
                  brand: brand,
                  scrollController: scrollController,
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  State<AddOrEditShopDialog> createState() => _AddOrEditShopDialogState();
}

class _AddOrEditShopDialogState extends State<AddOrEditShopDialog> {
  final _formkey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  String? _brandSlug;
  late double _rating;
  bool _isSubmitting = false;
  bool _stamped = false;
  final List<GalleryImage> _selectedImages = [];

  // DRINK FORM WIDGETS
  bool _showMiniDrinkForm = false;
  final _miniDrinkFormKey = GlobalKey<FormState>();
  final _miniDrinkNameCtrl = TextEditingController();
  final _miniDrinkNotesCtrl = TextEditingController();
  double _miniDrinkRating = 3.0;

  final List<DrinkFormData> _pendingDrinks = [];

  @override
  void initState() {
    super.initState();
    _brandSlug = widget.brand?.slug;
    if (_brandSlug != null) {
      _nameController = TextEditingController(text: widget.brand?.display);
    } else {
      _nameController = TextEditingController(text: widget.shop?.name ?? '');
    }
    _notesController = TextEditingController(text: widget.shop?.notes ?? '');
    _rating = widget.shop?.rating ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _miniDrinkNameCtrl.dispose();
    _miniDrinkNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    FocusScope.of(context).unfocus();
    final pickedImages = await showDialog<List<GalleryImage>>(
      context: context,
      builder: (context) => MultiselectImagePicker(maxImages: 5),
    );
    if (mounted) FocusScope.of(context).unfocus();
    if (pickedImages != null && pickedImages.isNotEmpty) {
      setState(() {
        _selectedImages.clear();
        _selectedImages.addAll(pickedImages);
      });
    }
  }

  void _handleSubmit(
    ShopMediaState shopMediaState,
    DrinkState drinkState,
    AchievementsState achievementState,
    FeedState feedState,
    AnalyticsService analytics,
    user,
  ) async {
    final isValid = _formkey.currentState?.validate() ?? false;
    if (!isValid) return;
    if (widget.shop == null && _rating <= 0) return;

    setState(() => _isSubmitting = true);

    final isNewShop = widget.shop == null;
    final userId = Supabase.instance.client.auth.currentUser!.id;

    try {
      final newShop =
          widget.shop?.copyWith(
            name: _nameController.text.trim(),
            rating: _rating,
            notes: _notesController.text.trim(),
            brandSlug: _brandSlug,
          ) ??
          Shop(
            name: _nameController.text.trim(),
            userId: userId,
            rating: _rating,
            notes: _notesController.text.trim(),
            brandSlug: _brandSlug,
          );
      final submittedShop = await widget.onSubmit(newShop);
      final shopId = submittedShop.id!;
      await shopMediaState.loadForShop(shopId, force: false);
      final hadBannerPath = shopMediaState.getBannerPath(shopId) != null;

      final List<String> tempIds = [];
      for (int idx = 0; idx < _selectedImages.length; idx++) {
        final img = _selectedImages[idx];
        final tempId = Uuid().v4();
        tempIds.add(tempId);
        shopMediaState.addPendingForShop(
          shopId,
          ShopMedia(
            id: tempId,
            shopId: shopId,
            userId: userId,
            imagePath: '',
            comment: img.comment,
            visibility: img.visibility,
            isBanner: idx == 0 && !hadBannerPath,
            localFile: img.file,
            isPending: true,
          ),
        );
      }

      await Future.wait(
        _selectedImages.asMap().entries.map((entry) async {
          final idx = entry.key;
          final img = entry.value;
          final tempId = tempIds[idx];

          try {
            final imagePath = await ImageUploaderHelper.uploadImage(
              file: img.file!,
              folder: 'shop-gallery',
            );

            final realMedia = ShopMedia(
              id: '', // Will be set by backend
              shopId: shopId,
              userId: userId,
              imagePath: imagePath,
              comment: img.comment,
              visibility: img.visibility,
              isBanner: idx == 0 && !hadBannerPath,
            );

            await shopMediaState.addMedia(realMedia, replacePendingId: tempId);
            await analytics.mediaUploaded(count: 1);
          } catch (e) {
            debugPrint('Error uploading images: $e');
            shopMediaState.removePendingForShop(shopId, tempId);
            if (e.toString().contains('statusCode: 409')) {
              notify('Image already exists, skipping', SnackType.info);
            } else if (mounted) {
              notify('Error uploading images', SnackType.error);
            }
          }
        }),
      );

      await achievementState.checkAndUnlockMediaUploadAchievement();

      await Future.wait(
        _pendingDrinks.asMap().entries.map((entry) async {
          final drink = entry.value;

          try {
            await drinkState.add(drink.toDrink(shopId: shopId), shopId);
            await analytics.drinkAdded(rating: drink.rating);
            await achievementState.checkAndUnlockDrinkAchievement(drinkState);
            await achievementState.checkAndUnlockNotesAchievement(drinkState);
          } catch (e) {
            debugPrint('Error adding drink: $e');
            notify('Error adding drink.', SnackType.error);
          }
        }),
      );

      _pendingDrinks.clear();

      if (isNewShop && submittedShop.id != null) {
        try {
          await feedState.finalizeShopAdd(
            currentUser: user,
            shopId: submittedShop.id!,
          );
        } catch (e) {
          debugPrint('Error adding feed event: $e');
        }
      }

      if (mounted) {
        if (!isNewShop) {
          Navigator.of(context).pop();
        } else {
          final addedId = submittedShop.id;
          if (addedId != null) {
            context.read<ShopState>().spotlightShop(addedId);
          }
          setState(() => _stamped = true);
          await Future.delayed(const Duration(milliseconds: 900));
          if (!mounted) return;
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Failed to submit shop: $e');
        notify('Failed to add shop', SnackType.error);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _openDrinkForm() {
    setState(() => _showMiniDrinkForm = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = widget.scrollController;
      if (controller == null || !controller.hasClients) return;
      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: BobaMotion.normal,
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _addPendingDrink() {
    if (!(_miniDrinkFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _pendingDrinks.add(
        DrinkFormData(
          name: _miniDrinkNameCtrl.text.trim(),
          rating: _miniDrinkRating,
          notes: _miniDrinkNotesCtrl.text.trim(),
          isFavorite: false,
        ),
      );
      _showMiniDrinkForm = false;
      _miniDrinkNameCtrl.clear();
      _miniDrinkNotesCtrl.clear();
      _miniDrinkRating = 3.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shopMediaState = context.read<ShopMediaState>();
    final drinkState = context.read<DrinkState>();
    final achievementState = context.read<AchievementsState>();
    final feedState = context.read<FeedState>();
    final analytics = context.read<AnalyticsService>();
    final user = context.read<UserState>().current;
    final isNewShop = widget.shop == null;
    final needsRating = isNewShop && _rating <= 0;

    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  BobaSpace.x4,
                  0,
                  BobaSpace.x4,
                  BobaSpace.x4,
                ),
                child: Form(
                  key: _formkey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ShopFormHeader(
                        brand: widget.brand,
                        isNewShop: isNewShop,
                      ),
                      if (_brandSlug == null) ...[
                        const SizedBox(height: BobaSpace.x4),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Shop Name',
                          ),
                          style: Theme.of(context).textTheme.titleLarge,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter a name'
                              : null,
                        ),
                      ],
                      const SizedBox(height: BobaSpace.x5),
                      Row(
                        children: [
                          Text(
                            'Your rating',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const Spacer(),
                          RatingText(
                            value: _rating,
                            size: RatingTextSize.large,
                          ),
                        ],
                      ),
                      const SizedBox(height: BobaSpace.x3),
                      RatingPicker(
                        rating: _rating,
                        onChanged: (val) => setState(() => _rating = val),
                      ),
                      if (needsRating) ...[
                        const SizedBox(height: BobaSpace.x2),
                        Text(
                          'Tap a star to rate it',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: context.boba.inkMuted),
                        ),
                      ],
                      const SizedBox(height: BobaSpace.x6),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          alignLabelWithHint: true,
                        ),
                        keyboardType: TextInputType.multiline,
                        minLines: 2,
                        maxLines: null,
                        maxLength: Constants.maxShopNotesLength,
                      ),
                      if (isNewShop) ...[
                        const SizedBox(height: BobaSpace.x4),
                        Text(
                          'Photos',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: BobaSpace.x3),
                        _buildPhotos(context),
                        const SizedBox(height: BobaSpace.x5),
                        Text(
                          'Drinks',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: BobaSpace.x3),
                        AnimatedSize(
                          duration: BobaMotion.normal,
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: _showMiniDrinkForm
                              ? _MiniDrinkForm(
                                  formKey: _miniDrinkFormKey,
                                  nameCtrl: _miniDrinkNameCtrl,
                                  notesCtrl: _miniDrinkNotesCtrl,
                                  rating: _miniDrinkRating,
                                  onRatingChanged: (v) =>
                                      setState(() => _miniDrinkRating = v),
                                  onCancel: () => setState(
                                    () => _showMiniDrinkForm = false,
                                  ),
                                  onAdd: _addPendingDrink,
                                )
                              : Align(
                                  alignment: Alignment.centerLeft,
                                  child: BobaButton(
                                    label: 'Add a drink',
                                    variant: BobaButtonVariant.secondary,
                                    size: BobaButtonSize.small,
                                    icon: const Icon(Icons.add_rounded),
                                    onPressed: _openDrinkForm,
                                  ),
                                ),
                        ),
                        if (_pendingDrinks.isNotEmpty) ...[
                          const SizedBox(height: BobaSpace.x3),
                          Wrap(
                            spacing: BobaSpace.x2,
                            runSpacing: BobaSpace.x2,
                            children: [
                              for (final drink in _pendingDrinks)
                                BobaChip(
                                  label: _drinkChipLabel(drink),
                                  trailing: const Icon(Icons.close_rounded),
                                  onTap: () => setState(
                                    () => _pendingDrinks.remove(drink),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: context.boba.outline,
                    width: BobaStroke.hairline,
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  BobaSpace.x4,
                  BobaSpace.x3,
                  BobaSpace.x4,
                  BobaSpace.x4 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Row(
                  children: [
                    BobaButton(
                      label: 'Cancel',
                      variant: BobaButtonVariant.tertiary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: BobaSpace.x2),
                    Expanded(
                      child: BobaButton(
                        label: isNewShop ? 'Add Shop' : 'Save',
                        expanded: true,
                        loading: _isSubmitting,
                        onPressed: needsRating
                            ? null
                            : () => _handleSubmit(
                                shopMediaState,
                                drinkState,
                                achievementState,
                                feedState,
                                analytics,
                                user,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_stamped) _AddedStamp(brand: widget.brand),
      ],
    );
  }

  Widget _buildPhotos(BuildContext context) {
    final tokens = context.boba;
    if (_selectedImages.isEmpty) {
      return BobaButton(
        label: 'Add photos',
        variant: BobaButtonVariant.secondary,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        expanded: true,
        onPressed: _pickImages,
      );
    }

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        primary: false,
        itemCount: _selectedImages.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: BobaSpace.x2),
        itemBuilder: (context, index) {
          if (index == _selectedImages.length) {
            return _PhotoActionTile(
              tooltip: 'Change photos',
              icon: Icons.edit_outlined,
              onTap: _pickImages,
            );
          }
          final image = _selectedImages[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(BobaRadius.md),
                child: Image.file(
                  image.file!,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                ),
              ),
              if (index == 0)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tokens.imageScrim.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(BobaRadius.pill),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        'Cover',
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: tokens.onImage),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedImages.removeAt(index)),
                  child: Tooltip(
                    message: 'Remove photo',
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: tokens.imageScrim.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(BobaRadius.pill),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: tokens.onImage,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _drinkChipLabel(DrinkFormData drink) {
  final name = drink.name.length > 28
      ? '${drink.name.substring(0, 28)}…'
      : drink.name;
  return '$name · ${drink.rating.toStringAsFixed(1)}';
}

class _ShopFormHeader extends StatelessWidget {
  const _ShopFormHeader({required this.brand, required this.isNewShop});

  final Brand? brand;
  final bool isNewShop;

  @override
  Widget build(BuildContext context) {
    final title = brand?.display ?? (isNewShop ? 'Add shop' : 'Edit shop');
    final subtitle = isNewShop ? 'Add to your dex' : 'Edit your visit';
    return Row(
      children: [
        if (brand != null) ...[
          BrandMark(
            name: brand!.display,
            slug: brand!.slug,
            iconPath: brand!.iconPath,
            size: BobaSize.markLg,
          ),
          const SizedBox(width: BobaSpace.x3),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: context.boba.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoActionTile extends StatelessWidget {
  const _PhotoActionTile({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(BobaRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BobaRadius.md),
          child: SizedBox(
            width: 88,
            height: 88,
            child: Icon(icon, color: tokens.inkMuted),
          ),
        ),
      ),
    );
  }
}

class _MiniDrinkForm extends StatelessWidget {
  const _MiniDrinkForm({
    required this.formKey,
    required this.nameCtrl,
    required this.notesCtrl,
    required this.rating,
    required this.onRatingChanged,
    required this.onCancel,
    required this.onAdd,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController notesCtrl;
  final double rating;
  final ValueChanged<double> onRatingChanged;
  final VoidCallback onCancel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(BobaRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BobaSpace.x3),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add a drink',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: BobaSpace.x2),
              TextFormField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Drink Name',
                  fillColor: tokens.surface,
                ),
                maxLength: Constants.maxDrinkNameLength,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: BobaSpace.x2),
              Row(
                children: [
                  Text('Rating', style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  RatingText(value: rating, size: RatingTextSize.medium),
                ],
              ),
              const SizedBox(height: BobaSpace.x2),
              RatingPicker(
                rating: rating,
                onChanged: onRatingChanged,
                size: 36,
              ),
              const SizedBox(height: BobaSpace.x2),
              TextFormField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  alignLabelWithHint: true,
                  fillColor: tokens.surface,
                ),
                keyboardType: TextInputType.multiline,
                maxLength: 120,
                maxLines: null,
                minLines: 2,
              ),
              const SizedBox(height: BobaSpace.x2),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  BobaButton(
                    label: 'Cancel',
                    variant: BobaButtonVariant.tertiary,
                    size: BobaButtonSize.small,
                    onPressed: onCancel,
                  ),
                  const SizedBox(width: BobaSpace.x2),
                  BobaButton(
                    label: 'Add',
                    size: BobaButtonSize.small,
                    onPressed: onAdd,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddedStamp extends StatelessWidget {
  const _AddedStamp({required this.brand});

  final Brand? brand;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final mark = brand == null
        ? Icon(Icons.check_circle_rounded, size: 88, color: tokens.success)
        : SizedBox(
            width: BobaSize.markXl,
            height: BobaSize.markXl,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                BrandMark(
                  name: brand!.display,
                  slug: brand!.slug,
                  iconPath: brand!.iconPath,
                  size: BobaSize.markXl,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tokens.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: tokens.bg, width: 3),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.check_rounded,
                        size: 22,
                        color: tokens.onImage,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

    return ColoredBox(
      color: tokens.bg.withValues(alpha: 0.94),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.7, end: 1),
              duration: BobaMotion.stamp,
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: mark,
            ),
            const SizedBox(height: BobaSpace.x4),
            Text(
              'Added to your dex',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
