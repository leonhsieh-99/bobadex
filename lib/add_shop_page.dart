import 'package:flutter/material.dart';
import 'dart:io';
import 'models/shop.dart';
import 'helpers/image_picker_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'rating_picker.dart';

class AddShopPage extends StatefulWidget {
  const AddShopPage({super.key});

  @override
  State<AddShopPage> createState() => _AddShopPageState();
}

class _AddShopPageState extends State<AddShopPage> {
  final _formkey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  double _rating = 0;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  void _submit() {
    print ('Starting submit');
    final shop = Shop(
      name: _nameController.text.trim(),
      rating: _rating,
      imagePath: _selectedImage?.path ?? '',
      imageUrl: '',
      drinks: [],
    );
    Navigator.pop(context, shop);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Boba Shop')),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formkey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final pickedFile = await pickImageWithDialog(context, _picker);
                      if (pickedFile != null) {
                        setState(() {
                          _selectedImage = pickedFile;
                        });
                      }
                    },
                    child: _selectedImage == null
                      ? Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(child: Text('Tap to select an optional image')),
                      )
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
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
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Add Shop'),
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