import 'package:bobadex/helpers/show_snackbar.dart';
import 'package:bobadex/models/feed_event.dart';
import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/feed_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/pages/shop_detail_page.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:bobadex/widgets/image_widgets/fullscreen_image_viewer.dart';
import 'package:bobadex/widgets/image_widgets/multiselect_image_picker_dialog.dart';
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

  const AddOrEditShopDialog ({
    super.key,
    this.shop,
    required this.onSubmit,
    this.brand,
  });

  @override
  State<AddOrEditShopDialog> createState() => _AddOrEditShopDialogState();
}

class _AddOrEditShopDialogState extends State<AddOrEditShopDialog> {
  final _formkey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  String ? _brandSlug;
  double _rating = 0;
  bool _isSubmitting = false;
  final List<GalleryImage> _selectedImages = [];

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
    super.dispose();
  }

  Future<void> _pickImages() async {
    FocusScope.of(context).unfocus();
    final pickedImages = await showDialog<List<GalleryImage>>(
      context: context,
      builder: (context) => MultiselectImagePickerDialog(),
    );
    if (mounted) FocusScope.of(context).unfocus();
    if (pickedImages != null && pickedImages.isNotEmpty) {
      setState(() {
        _selectedImages.clear();
        _selectedImages.addAll(pickedImages);
      });
    }
  }

  void _handleSubmit(ShopMediaState shopMediaState, AchievementsState achievementState, FeedState feedState, user) async {
    final isValid = _formkey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isSubmitting = true);

    final isNewShop = widget.shop == null;
    bool bannerExists = false;
    if (!isNewShop) {
      bannerExists = shopMediaState.getBannerId(widget.shop!.id!) != null;
    }

    try {
      final newShop = widget.shop?.copyWith(
        name: _nameController.text.trim(),
        rating: _rating,
        notes: _notesController.text.trim(),
        brandSlug: _brandSlug,
      ) ?? Shop(
        name: _nameController.text.trim(),
        rating: _rating,
        notes: _notesController.text.trim(),
        brandSlug: _brandSlug,
      );
      final submittedShop = await widget.onSubmit(newShop);

      List<Map<String, dynamic>> uploadedImages = [];

      await Future.wait(_selectedImages.asMap().entries.map((entry) async {
        final idx = entry.key;
        final img = entry.value;

        final imagePath = await ImageUploaderHelper.uploadImage(
          file: img.file!,
          folder: 'shop-gallery',
          generateThumbnail: true,
        );

        uploadedImages.add({
          "path": imagePath,
          "comment": img.comment,
        });

        final tempId = Uuid().v4();
        final media = ShopMedia(
            id: tempId,
            shopId: submittedShop.id!,
            userId: Supabase.instance.client.auth.currentUser!.id,
            imagePath: imagePath,
            comment: img.comment,
            visibility: img.visibility,
            isBanner: idx == 0 && !bannerExists,  // first image is banner
          );
        shopMediaState.addPendingMedia(media);

        try {
          final insertedMedia = await shopMediaState.addMedia(media);
          await achievementState.checkAndUnlockMediaUploadAchievement(shopMediaState);
          shopMediaState.replacePendingMedia(tempId, insertedMedia);
        } catch (e) {
          shopMediaState.removePendingMedia(tempId);
          if (mounted) { showAppSnackBar(context, 'Error uploading images', type: SnackType.error); }
        }
      }));

      try {
        await feedState.addFeedEvent(
          FeedEvent(
            id: '',
            userId: user.id,
            objectId: submittedShop.id ?? '',
            eventType: 'shop_add',
            brandSlug: widget.brand?.slug != null && widget.brand!.slug.isNotEmpty ? widget.brand!.slug : null,
            payload: {
              "user_avatar": user.thumbUrl,
              "user_name": user.displayName,
              "shop_name": submittedShop.name,
              "notes": submittedShop.notes,
              "images": uploadedImages,
              "rating": submittedShop.rating,
            },
            isBackfill: false,
          ),
        );
      } catch (e) {
        debugPrint('Error adding feed event: $e');
      }

      if (mounted) {
        showAppSnackBar(context, widget.shop == null ? 'Shop added successfully' : 'Shop saved successfully', type: SnackType.success);
        Navigator.of(context).popUntil((route) => route.isFirst);
        if (!isNewShop) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ShopDetailPage(user: user, shop: submittedShop),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to submit', type: SnackType.error);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopMediaState = context.read<ShopMediaState>();
    final achievementState = context.read<AchievementsState>();
    final feedState = context.read<FeedState>();
    final user = context.read<UserState>().user;
    final isNewShop = widget.shop == null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Form(
              key: _formkey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isSubmitting) const LinearProgressIndicator(minHeight: 2),
                  // --- TITLE & NAME FIELD ---
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      isNewShop ? 'Add Shop' : 'Edit Shop',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // --- NAME FIELD
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _brandSlug != null
                      ? ListTile(
                          minTileHeight: 30,
                          minVerticalPadding: 4,
                          leading: Icon(Icons.storefront_rounded),
                          title: Text(
                            _nameController.text,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.left,
                          )
                        )
                      : TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Shop Name',
                          ),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.left,
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Enter a name' : null,
                        ),
                  ),
                  const SizedBox(height: 2),
                  // --- RATING ---
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Text('Rating', style: Theme.of(context).textTheme.labelLarge),
                    ),
                  ),
                  StatefulBuilder(
                    builder: (context, setState) {
                      return RatingPicker(
                        rating: _rating,
                        onChanged: (val) => setState(() => _rating = val),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // --- NOTES ---
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    minLines: 2,
                  ),
                  // --- ADD PHOTOS (ONLY for new shop) ---
                  if (isNewShop) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add Photos'),
                      onPressed: _pickImages,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final image = _selectedImages[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  image.file!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedImages.removeAt(index));
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.close, size: 20, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // --- ACTION BUTTONS ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSubmitting
                          ? null
                          : () => _handleSubmit(shopMediaState, achievementState, feedState, user),
                        child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : (isNewShop ? Text('Add Shop') : Text('Save')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}