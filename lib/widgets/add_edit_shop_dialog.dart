import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/pages/add_shop_search_page.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/shop.dart';
import '../models/brand.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];

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
    final pickedImages = await _picker.pickMultiImage();
    if (pickedImages.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedImages.map((f) => File(f.path)));
      });
    }
  }

  void _handleSubmit(ShopMediaState shopMediaState) async {
    final isValid = _formkey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isSubmitting = true);

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

      await Future.wait(_selectedImages.map((file) async {
        final imagePath = await ImageUploaderHelper.uploadImage(
          file: file,
          folder: 'shop-gallery',
          generateThumbnail: true,
        );

        await shopMediaState.addMedia(
          ShopMedia(
            id: '',
            shopId: submittedShop.id!,
            userId: Supabase.instance.client.auth.currentUser!.id,
            imagePath: imagePath
          )
        );
      }));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop and images added successfully')),
      );

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopState>().getShop(widget.shop?.id!);
    final shopMediaState = context.read<ShopMediaState>();
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSubmitting) const LinearProgressIndicator(minHeight: 2),
                  Text(
                    widget.shop == null ? 'Add Shop' : 'Edit Shop',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                const SizedBox(height: 12),
                Form(
                  key: _formkey,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 450,
                      maxHeight: MediaQuery.of(context).size.height * 0.75,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                      image,
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(labelText: 'Shop Name'),
                                enabled: _brandSlug == null,
                                validator: (value) => 
                                  value == null || value.isEmpty ? 'Enter a name' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: Icon(_brandSlug == null ? Icons.link : Icons.swap_horiz),
                              label: Text(_brandSlug == null ? "Link" : "Change"),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                minimumSize: Size(50 , 40),
                              ),
                              onPressed: () async {
                                await Navigator.push<String>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddShopSearchPage(
                                      onBrandSelected: (brand) {
                                        setState(() {
                                          _brandSlug = brand.slug;
                                          _nameController = TextEditingController(text: brand.display);
                                        });
                                      },
                                      existingShopId: shop!.id,
                                    ),
                                  )
                                );
                              }
                            ),
                          ]
                        ),
                        const SizedBox(height: 16),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _isSubmitting ? null : _handleSubmit(shopMediaState),
                      child: _isSubmitting
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                        : (shop == null ? Text('Add Shop'): Text('Save'))
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}