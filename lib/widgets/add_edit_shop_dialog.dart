import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/feed_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:bobadex/widgets/image_widgets/fullscreen_image_viewer.dart';
import 'package:bobadex/widgets/image_widgets/multiselect_image_picker.dart';
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
  late double _rating;
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
    _rating = widget.shop?.rating ?? 3;
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
    AchievementsState achievementState,
    FeedState feedState,
    user,
  ) async {
    final isValid = _formkey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isSubmitting = true);

    final isNewShop = widget.shop == null;
    final userId = Supabase.instance.client.auth.currentUser!.id;
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
      ) ??
          Shop(
            name: _nameController.text.trim(),
            userId: userId,
            rating: _rating,
            notes: _notesController.text.trim(),
            brandSlug: _brandSlug,
          );
      final submittedShop = await widget.onSubmit(newShop);

      final List<String> tempIds = [];
      for (int idx = 0; idx < _selectedImages.length; idx++) {
        final img = _selectedImages[idx];
        final tempId = Uuid().v4();
        tempIds.add(tempId);
        shopMediaState.addPendingMedia(
          ShopMedia(
            id: tempId,
            shopId: submittedShop.id!,
            userId: Supabase.instance.client.auth.currentUser!.id,
            imagePath: '',
            comment: img.comment,
            visibility: img.visibility,
            isBanner: idx == 0 && !bannerExists,
            localFile: img.file,
            isPending: true,
          ),
        );
      }

      List<Map<String, dynamic>?> uploadedImages = List.filled(_selectedImages.length, null);

      await Future.wait(_selectedImages.asMap().entries.map((entry) async {
        final idx = entry.key;
        final img = entry.value;
        final tempId = tempIds[idx];

        try {
          final imagePath = await ImageUploaderHelper.uploadImage(
            file: img.file!,
            folder: 'shop-gallery',
          );

          uploadedImages[idx] = {
            "path": imagePath,
            "comment": img.comment,
          };

          final realMedia = ShopMedia(
            id: '', // Will be set by backend
            shopId: submittedShop.id!,
            userId: Supabase.instance.client.auth.currentUser!.id,
            imagePath: imagePath,
            comment: img.comment,
            visibility: img.visibility,
            isBanner: idx == 0 && !bannerExists,
          );

          final insertedMedia = await shopMediaState.addMedia(realMedia);
          await achievementState.checkAndUnlockMediaUploadAchievement(shopMediaState);
          shopMediaState.replacePendingMedia(tempId, insertedMedia);
        } catch (e) {
          debugPrint('Error uploading images: $e');
          shopMediaState.removePendingMedia(tempId);
          if (e.toString().contains('statusCode: 409')) {
            notify('Image already exists, skipping', SnackType.info);
          } else if (mounted) {
            notify('Error uploading images', SnackType.error);
          }
        }
      }));

      uploadedImages = uploadedImages.whereType<Map<String, dynamic>>().toList();

      if (isNewShop && submittedShop.id != null) {
        try {
          await feedState.finalizeShopAdd(
            currentUser: user,
            shopId: submittedShop.id!
          );
        } catch (e) {
          debugPrint('Error adding feed event: $e');
        }
      }

      if (mounted) {
        if (!isNewShop) {
          Navigator.of(context).pop();
        } else {
          notify('Shop added', SnackType.success);
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


  @override
  Widget build(BuildContext context) {
    final shopMediaState = context.read<ShopMediaState>();
    final achievementState = context.read<AchievementsState>();
    final feedState = context.read<FeedState>();
    final user = context.read<UserState>().current;
    final isNewShop = widget.shop == null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewInsets = MediaQuery.of(context).viewInsets;
          final maxHeight = constraints.maxHeight - viewInsets.bottom - 24; // 24 for margin

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxHeight > 300 ? maxHeight : 300, // minimum height
              ),
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
                                  ))
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
                            padding: const EdgeInsets.only(top: 12, bottom: 12),
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
        },
      ),
    );
  }
}