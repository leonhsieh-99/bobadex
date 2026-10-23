import 'package:bobadex/auth/delete_account.dart';
import 'package:bobadex/config/constants.dart';
import 'package:bobadex/helpers/image_uploader_helper.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/utils/validators.dart';
import 'package:bobadex/pages/setting_pages/email_change_page.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../helpers/image_picker_helper.dart';
import '../../state/user_state.dart';
import '../../widgets/text_field_edit_dialog.dart';

class SettingsAccountPage extends StatefulWidget {
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

  void _handleImagePick(UserState userState) async {
    bool imageExits =
        userState.current.profileImagePath != null &&
        userState.current.profileImagePath!.isNotEmpty;
    final pickedFile = await pickImageWithDialog(context, _picker, imageExits);
    final oldImagePath = userState.current.profileImagePath;
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
        _removeExistingImage = pickedFile.path != oldImagePath;
        _isLoading = true;
      });
    }

    final newImagePath = _selectedImage?.path;
    String path = '';

    try {
      if (newImagePath != null && newImagePath.isNotEmpty) {
        try {
          path = await ImageUploaderHelper.uploadImage(
            file: File(newImagePath),
            folder: 'user-uploads',
          );
        } catch (e) {
          debugPrint('Image upload failed: $e');
        }

        userState.setProfileImagePath(path);
      }
      if (_removeExistingImage &&
          oldImagePath != null &&
          oldImagePath.isNotEmpty) {
        try {
          ImageUploaderHelper.deleteImage(oldImagePath);
        } catch (e) {
          debugPrint('Error deleting image: $e');
        }
      }
      await Supabase.instance.client
          .from('users')
          .update({'profile_image_path': path})
          .eq('id', userState.current.id);
    } catch (e) {
      notify('Error updating profile picture', SnackType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    final user = userState.current;

    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(title: const Text('Manage Account')),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () => _handleImagePick(userState),
                        child: ThumbPic(path: user.profileImagePath, size: 150),
                      ),
                    ),
                    const SizedBox(height: 16),

                    ListTile(
                      leading: const Text(
                        'Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      trailing: Text(
                        user.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 18,
                        ),
                      ),
                      onTap: () async {
                        final newName = await textFieldEditDialog(
                          context: context,
                          title: 'Edit Name',
                          initalValue: user.displayName,
                          maxLength: Constants.maxNameLength,
                          maxLines: 1,
                        );
                        if (newName != null && newName != user.displayName) {
                          try {
                            await userState.setDisplayName(newName);
                          } catch (e) {
                            notify('Error updating name.', SnackType.error);
                          }
                        }
                      },
                    ),

                    ListTile(
                      leading: const Text(
                        'Username',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      trailing: Text(
                        user.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 18,
                        ),
                      ),
                      onTap: () async {
                        final newUsername = await textFieldEditDialog(
                          context: context,
                          title: 'Edit Username',
                          initalValue: user.username,
                          maxLength: Constants.maxUsernameLength,
                          maxLines: 1,
                          validator: Validators.validateUsername,
                          asyncValidator: (username) async {
                            final exists = await userState.usernameExists(
                              username,
                            );
                            return exists ? 'Username is taken' : null;
                          },
                        );
                        if (newUsername != null &&
                            newUsername != user.username) {
                          try {
                            await userState.setUsername(newUsername);
                          } catch (e) {
                            notify('Error updating username.', SnackType.error);
                          }
                        }
                      },
                    ),

                    ListTile(
                      leading: const Text(
                        'Email',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      trailing: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          Supabase.instance.client.auth.currentUser?.email ??
                              '—',
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EmailChangePage(),
                          ),
                        );
                        if (context.mounted) setState(() {});
                      },
                    ),

                    ListTile(
                      leading: const Text(
                        'Bio',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      trailing: Text(
                        (user.bio != null && user.bio!.isNotEmpty)
                            ? (user.bio!.length > 10
                                  ? '${user.bio!.substring(0, 10)}...'
                                  : user.bio!)
                            : 'Add bio',
                        style: const TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 18,
                        ),
                      ),
                      onTap: () async {
                        final newBio = await textFieldEditDialog(
                          context: context,
                          title: 'Edit Bio',
                          initalValue: user.bio ?? '',
                          maxLength: 200,
                          maxLines: 5,
                        );
                        if (newBio != null && newBio != user.bio) {
                          try {
                            await userState.setBio(newBio);
                          } catch (e) {
                            notify('Error updating bio.', SnackType.error);
                          }
                        }
                      },
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),

              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.boba.danger,
                      foregroundColor: context.boba.onAccent,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final confirmed = await confirmAccountDeletion(
                              context,
                            );
                            if (!confirmed || !context.mounted) return;
                            setState(() => _isLoading = true);
                            final failure = await deleteConfirmedAccount(
                              context,
                            );
                            if (!mounted) return;
                            setState(() => _isLoading = false);
                            if (failure != null) {
                              notify(failure, SnackType.error);
                            }
                          },
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: context.boba.imageScrim.withValues(alpha: 0.1),
              child: Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.boba.onImage,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
