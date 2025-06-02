import 'package:flutter/material.dart';
import '../../helpers/image_picker_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SettingsAccountPage extends StatefulWidget{
  const SettingsAccountPage({super.key});

  @override
  State<SettingsAccountPage> createState() => _SettingsAccountPageState();
}

class _SettingsAccountPageState extends State<SettingsAccountPage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  _handleImagePick() async {
    final pickedFile = await pickImageWithDialog(context, _picker);
    if (pickedFile == null) return;

    setState(() {
      _selectedImage = pickedFile;
      _isLoading = true;
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Account'),
      ),
      body: Column(
        children: [
          GestureDetector(
            onTap: _handleImagePick(),
            child: Stack(

            ),
          )
        ],
      ),
    );
  }
}