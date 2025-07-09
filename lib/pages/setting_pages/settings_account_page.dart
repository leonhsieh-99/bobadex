import 'package:bobadex/helpers/image_uploader_helper.dart';
import 'package:bobadex/helpers/show_snackbar.dart';
import 'package:bobadex/utils/validators.dart';
import 'package:bobadex/widgets/change_password_dialong.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../helpers/image_picker_helper.dart';
import '../../state/user_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/text_field_edit_dialog.dart';

class SettingsAccountPage extends StatefulWidget{
  const SettingsAccountPage({super.key});

  @override
  State<SettingsAccountPage> createState() => _SettingsAccountPageState();
}

class _SettingsAccountPageState extends State<SettingsAccountPage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;
  bool _removeExistingImage = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }


  _handleImagePick(UserState userState) async {
    bool imageExits = userState.user.profileImagePath != null && userState.user.profileImagePath!.isNotEmpty;
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
    final oldImagePath = userState.user.profileImagePath;
    String path = '';

    try {
      if (newImagePath != null && newImagePath.isNotEmpty) {
        try {
          path = await ImageUploaderHelper.uploadImage(
            file: File(newImagePath),
            folder: 'user-uploads',
            generateThumbnail: true,
          );
        } catch (e) {
          debugPrint('Image upload failed: $e');
        }

        userState.setProfileImagePath(path);

        if (mounted) showAppSnackBar(context, 'Image uploaded', type: SnackType.success);
      }
      if (_removeExistingImage && oldImagePath != null && oldImagePath.isNotEmpty) {
        try {
          ImageUploaderHelper.deleteImage(
            oldImagePath,
          );
        }
        catch (e) {
          debugPrint('Error deleting image: $e');
        }
      }
      await Supabase.instance.client
        .from('users')
        .update({'profile_image_path': path})
        .eq('id', userState.user.id);
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Error updating profile picture', type: SnackType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    final user = userState.user;
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Manage Account'),
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () => _handleImagePick(userState),
                      child: (user.profileImagePath != null && user.profileImagePath != '')
                        ? CircleAvatar(
                            radius: 70,
                            backgroundImage: CachedNetworkImageProvider(
                              user.thumbUrl,
                            ),
                          )
                        : CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.grey[200],
                          child: Icon(Icons.person, size: 80, color: Colors.grey),
                        )
                    )
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    leading: const Text('Name', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      )),
                      trailing: Text(user.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 18,
                        )
                    ),
                    onTap: () => textFieldEditDialog(
                      context: context,
                      title: 'Edit Name',
                      initalValue: user.displayName,
                      maxLength: 20,
                      maxLines: 1,
                      onSave: (newName) async {
                        try { 
                          await userState.setDisplayName(newName);
                        } catch (e) {
                          if (context.mounted) showAppSnackBar(context, 'Error updating name.', type: SnackType.error);
                        }
                      },
                      validator: Validators.validateDisplayName,
                    ),
                  ),
                  ListTile(
                    leading: const Text('Username', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      )),
                      trailing: Text(user.username,
                        style: TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 18,
                        )
                    ),
                    onTap: () => textFieldEditDialog(
                      context: context,
                      title: 'Edit Username',
                      initalValue: user.username,
                      maxLength: 15,
                      maxLines: 1,
                      onSave: (newUsername) async {
                        try { 
                          await userState.setUsername(newUsername);
                        } catch (e) {
                          if (context.mounted) showAppSnackBar(context, 'Erro updating username.', type: SnackType.error);
                        }
                      },
                      validator: Validators.validateUsername,
                      asyncValidator: (username) async {
                        final exists = await userState.usernameExists(username);
                        if (exists) {
                          return 'Username is taken';
                        }
                        return null;
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Text('Bio', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      )),
                      trailing: Text(user.bio != null && user.bio!.isNotEmpty ? '${user.bio!.length < 10 ? user.bio! : user.bio?.substring(0, 10)}...' : 'Add bio',
                        style: TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 18,
                        )
                    ),
                    onTap: () => textFieldEditDialog(
                      context: context,
                      title: 'Edit Bio',
                      initalValue: user.bio ?? '',
                      maxLength: 200,
                      maxLines: 5,
                      onSave: (newBio) async {
                        try { 
                          await userState.setBio(newBio);
                        } catch (e) {
                          if (context.mounted) showAppSnackBar(context, 'Error updating username.', type: SnackType.error);
                        }
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Text('Change Password', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    )),
                    trailing: Icon(
                      Icons.lock,
                      color: Colors.black.withOpacity(0.6),
                    ),
                    onTap: () => changePasswordDialog(context),
                  ),
                ],
              ),
            ),
          ),
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