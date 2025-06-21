import 'package:bobadex/config/constants.dart';
import 'package:bobadex/helpers/image_picker_helper.dart';
import 'package:bobadex/helpers/image_uploader_helper.dart';
import 'package:bobadex/models/tea_room.dart';
import 'package:bobadex/state/tea_room_state.dart';
import 'package:bobadex/widgets/text_field_edit_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class ManageRoomPage extends StatefulWidget {
  final String roomId;
  const ManageRoomPage({super.key, required this.roomId});

  @override
  State<ManageRoomPage> createState() => _ManageRoomPageState();
}

class _ManageRoomPageState extends State<ManageRoomPage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _removeExistingImage = false;
  bool _isLoading = false;

  _handleImagePick(TeaRoomState teaRoomState, TeaRoom teaRoom) async {
    bool imageExits = teaRoom.roomImagePath != null && teaRoom.roomImagePath!.isNotEmpty;
    final pickedFile = await pickImageWithDialog(context, _picker, imageExits);
    if (pickedFile == null) return;
    if (pickedFile.path.isNotEmpty) _removeExistingImage = true;

    if (pickedFile.path.isEmpty) {
      setState(() {
        _selectedImage = null;
        _removeExistingImage = true;
        _isLoading = true;
      });
    } else {
      setState(() {
        _selectedImage = pickedFile;
        _removeExistingImage = true;
        _isLoading = true;
      });
    }

    final newImagePath = _selectedImage?.path;
    final oldImagePath = teaRoom.roomImagePath;
    String path = '';

    try {
      if (newImagePath != null && newImagePath.isNotEmpty) {
        try {
          path = await ImageUploaderHelper.uploadImage(
            file: File(newImagePath),
            folder: 'tea-room-uploads',
            generateThumbnail: true,
          );
        } catch (e) {
          print('Image upload failed: $e');
        }

        teaRoomState.update(teaRoom.copyWith(roomImagePath: path));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Image uploaded')),
        );
      }
      if (_removeExistingImage && oldImagePath != null && oldImagePath.isNotEmpty) {
        try {
          ImageUploaderHelper.deleteImage(
            oldImagePath,
          );
          _removeExistingImage = false;
        }
        catch (e) {
          print('Error deleting image: $e');
        }
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Failed to update picture')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teaRoomState = context.watch<TeaRoomState>();
    final teaRoom = teaRoomState.getTeaRoom(widget.roomId);
    final imageExists = teaRoom.roomImagePath != null && teaRoom.roomImagePath!.isNotEmpty;
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Tea Room Settings'),
          ),
          body: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _handleImagePick(teaRoomState, teaRoom),
                  child: (_selectedImage != null || (imageExists && _removeExistingImage))
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _selectedImage != null
                      ? Image.file(_selectedImage!, height: 150, width: double.infinity, fit: BoxFit.cover)
                      : CachedNetworkImage(
                        imageUrl: teaRoom.imageUrl,
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
                      child: const Center(child: Text('Tap to select image')),
                    )
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Change room name'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () async => textFieldEditDialog(
                    context: context,
                    title: 'Edit Name',
                    initalValue: teaRoom.name,
                    maxLength: Constants.teaRoomNameLen,
                    maxLines: 1,
                    onSave: (newName) async {
                      try { 
                        await teaRoomState.update(teaRoom.copyWith(name: newName));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update name'))
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Change room description'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () async => textFieldEditDialog(
                    context: context,
                    title: 'Edit Description',
                    initalValue: teaRoom.description ?? '',
                    maxLength: Constants.teaRoomDescriptionLen,
                    maxLines: 4,
                    onSave: (newDescription) async {
                      try { 
                        await teaRoomState.update(teaRoom.copyWith(description: newDescription));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update description.'))
                        );
                      }
                    },
                  ),
                ),
                const Spacer(),
                Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.delete_forever),
                    style: AppButtonStyles.deleteButtonStyle,
                    label: Text('Delete Room'),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Delete Tea Room?'),
                          content: Text('Are you sure you want to delete this room - ${teaRoom.name}? This cannot be undone'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('Delete', style: TextStyle(color: Colors.red))
                            )
                          ],
                        )
                      );
                      if (confirm == true) {
                        try {
                          await teaRoomState.delete(widget.roomId);
                          if (context.mounted) {
                            for (int i = 0; i < 3; i++) {
                              Navigator.of(context).pop();
                            }
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Error deleting the room'))
                          );
                        }
                      }
                    },
                  ),
                )
              ],
            ),
          )
        ),
      if (_isLoading)
        Container(
          color: Colors.black.withOpacity(0.1),
          child: const Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        )
      ]
    );
  }
}