import 'package:flutter/material.dart';
import 'dart:io';
import 'models/shop.dart';
import 'helpers/image_picker_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rating_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AddOrEditShopDialog extends StatefulWidget {
  final Shop? initialData;
  final void Function(Shop) onSubmit;

  const AddOrEditShopDialog ({
    super.key,
    this.initialData,
    required this.onSubmit,
  });

  @override
  State<AddOrEditShopDialog> createState() => _AddOrEditShopDialogState();
}

class _AddOrEditShopDialogState extends State<AddOrEditShopDialog> {
  final _formkey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  double _rating = 0;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _removeExistingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?.name ?? '');
    _notesController = TextEditingController(text: widget.initialData?.notes ?? '');
    _rating = widget.initialData?.rating ?? 0;
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
    final oldImagePath = widget.initialData?.imagePath;

    String supabasePath = '';

    try {
      bool uploadedNewImage = false;

      if (newImagePath != null && File(newImagePath).existsSync()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        supabasePath = 'shop-gallery/$timestamp.jpg';

        final fullBytes = await FlutterImageCompress.compressWithFile(
          minWidth: 800,
          newImagePath,
          quality: 80,
        );

        final thumbBytes = await FlutterImageCompress.compressWithFile(
          newImagePath,
          minWidth: 300,
          quality: 70,
        );

        try {
          await Supabase.instance.client.storage
              .from('media-uploads')
              .uploadBinary(
                supabasePath,
                fullBytes!,
                fileOptions: const FileOptions(
                  contentType: 'image/jpeg',
                  cacheControl: 'public, max-age=31536000',
                ),
              );
        } catch (e) {
          print('❌ Full image upload failed: $e');
          throw e;
        }

        await Future.delayed(const Duration(milliseconds: 200)); // mitigate overload

        try {
          await Supabase.instance.client.storage
              .from('media-uploads')
              .uploadBinary(
                'thumbs/$supabasePath',
                thumbBytes!,
                fileOptions: const FileOptions(
                  contentType: 'image/jpeg',
                  cacheControl: 'public, max-age=31536000',
                ),
              );
        } catch (e) {
          print('❌ Thumbnail upload failed: $e');
          throw e;
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
          await Supabase.instance.client.storage.from('media-uploads').remove([
            oldImagePath,
            'thumbs/$oldImagePath',
          ]);
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
        widget.initialData?.copyWith(
              name: _nameController.text.trim(),
              rating: _rating,
              imagePath: supabasePath,
              notes: _notesController.text.trim(),
            ) ??
            Shop(
              name: _nameController.text.trim(),
              rating: _rating,
              imagePath: supabasePath,
              notes: _notesController.text.trim(),
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
                            final pickedFile = await pickImageWithDialog(context, _picker);
                            if (pickedFile != null) {
                              setState(() {
                                _selectedImage = pickedFile;
                                _removeExistingImage = false;
                              });
                            }
                          },
                          child: (_selectedImage != null ||
                            (widget.initialData?.imagePath != null &&
                            widget.initialData!.imagePath!.isNotEmpty &&
                            !_removeExistingImage))
                              ? Stack (
                                alignment: Alignment.topRight,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _selectedImage != null
                                      ? Image.file(_selectedImage!, height: 150, width: double.infinity, fit: BoxFit.cover)
                                      : Image.network(
                                        Supabase.instance.client.storage
                                          .from('media-uploads')
                                          .getPublicUrl(widget.initialData!.imagePath!),
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _selectedImage = null;
                                        _removeExistingImage = true;
                                      });
                                    },
                                  ),
                                ],
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
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Shop Name'),
                          validator: (value) => 
                            value == null || value.isEmpty ? 'Enter a name' : null,
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
                        : (widget.initialData == null ? Text('Add Shop'): Text('Save'))
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