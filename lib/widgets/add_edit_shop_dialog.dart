import 'package:bobadex/pages/add_shop_search_page.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/shop.dart';
import '../models/brand.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rating_picker.dart';
import '../helpers/image_picker_helper.dart';
import '../helpers/image_uploader_helper.dart';

class AddOrEditShopDialog extends StatefulWidget {
  final Shop? shop;
  final void Function(Shop) onSubmit;
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
  File? _selectedImage;
  bool _removeExistingImage = false;

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


  void _handleSubmit() async {
    final isValid = _formkey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isSubmitting = true);
    final newImagePath = _selectedImage?.path;
    final oldImagePath = widget.shop?.imagePath;

    String supabasePath = '';

    try {
      bool uploadedNewImage = false;
      if (newImagePath != null && File(newImagePath).existsSync()) {
        try {
          supabasePath = await ImageUploaderHelper.uploadImage(
            file: File(newImagePath),
            folder: 'shop-gallery',
            generateThumbnail: true,
          );
        } catch (e) {
          print('❌ Full image upload failed: $e');
        }
        uploadedNewImage = true;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded')),
        );
      }

      // Delete old image if new one was uploaded or user removed it
      if ((uploadedNewImage || _removeExistingImage) &&
          oldImagePath != null &&
          oldImagePath.isNotEmpty &&
          !oldImagePath.startsWith('/')) {
        try {
          ImageUploaderHelper.deleteImage(oldImagePath);
          print('Deleted old image: $oldImagePath');
        } catch (e) {
          print('Failed to delete old image: $e');
        }
      }

      // Set to empty string if no image remains
      if (_removeExistingImage && newImagePath == null) {
        supabasePath = '';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image removed')),
        );
      } else if (!uploadedNewImage) {
        // fallback to old image if nothing changed
        supabasePath = oldImagePath ?? '';
      }

      // Submit to parent
      widget.onSubmit(
        widget.shop?.copyWith(
          name: _nameController.text.trim(),
          rating: _rating,
          imagePath: supabasePath,
          notes: _notesController.text.trim(),
          brandSlug: _brandSlug,
        ) ??
        Shop(
          name: _nameController.text.trim(),
          rating: _rating,
          imagePath: supabasePath,
          notes: _notesController.text.trim(),
          brandSlug: _brandSlug,
        ),
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
    final imageExists = shop?.imagePath != null && shop!.imagePath!.isNotEmpty;
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
                  'Add Shop',
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final pickedFile = await pickImageWithDialog(context, _picker, imageExists);
                            if (pickedFile != null) {
                              setState(() {
                                _selectedImage = pickedFile;
                                if (pickedFile.path == '') {
                                  _removeExistingImage = true;
                                  _selectedImage = null;
                                } else {
                                  _removeExistingImage = false;
                                }
                              });
                            }
                          },
                          child: (_selectedImage != null ||
                            (imageExists && !_removeExistingImage))
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _selectedImage != null
                                    ? Image.file(_selectedImage!, height: 150, width: double.infinity, fit: BoxFit.cover)
                                    : Image.network(
                                      Supabase.instance.client.storage
                                        .from('media-uploads')
                                        .getPublicUrl(shop!.imagePath!),
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                )
                              : Container(
                                  height: 150,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(child: Text('Tap to select an optional image')),
                                )
                        ),
                        const SizedBox(height: 16),
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
                      onPressed: _isSubmitting ? null : _handleSubmit,
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