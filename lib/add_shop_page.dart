import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'models/shop.dart';

class AddShopPage extends StatefulWidget {
  const AddShopPage({super.key});

  @override
  State<AddShopPage> createState() => _AddShopPageState();
}

class _AddShopPageState extends State<AddShopPage> {
  final _formkey = GlobalKey<FormState>();
  final _nameComtroller = TextEditingController();
  final _ratingController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet(
      context: context,
      builder: (builder) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),  
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pick a photo'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      }
    );
    if (source != null) {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    }
  }

  void _submit() {
    if (_formkey.currentState!.validate()) {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image')),
        );
        return;
      }
      final shop = Shop(
        name: _nameComtroller.text.trim(),
        rating: double.parse(_ratingController.text),
        imageUrl: _selectedImage!.path,
      );
      Navigator.pop(context, shop);
    }
  }

  @override
  void dispose() {
    _nameComtroller.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Boba Shop')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formkey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                  child: _selectedImage == null ? const Icon(Icons.add_a_photo) : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameComtroller,
                decoration: const InputDecoration(labelText: 'Shop Name'),
                validator: (value) => 
                  value == null || value.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ratingController,
                decoration: const InputDecoration(labelText: 'Rating (0-5)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final num = double.tryParse(value ?? '');
                  if (num == null || num < 0 || num > 5) {
                    return 'Enter a rating from 0 to 5';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Add Shop'
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}