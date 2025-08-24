import 'package:bobadex/config/constants.dart';
import 'package:bobadex/helpers/export_data.dart';
import 'package:bobadex/helpers/image_uploader_helper.dart';
import 'package:bobadex/notification_bus.dart';
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


  void _handleImagePick(UserState userState) async {
    bool imageExits = userState.user.profileImagePath != null && userState.user.profileImagePath!.isNotEmpty;
    final pickedFile = await pickImageWithDialog(context, _picker, imageExits);
    final oldImagePath = userState.user.profileImagePath;
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
            generateThumbnail: true,
          );
        } catch (e) {
          debugPrint('Image upload failed: $e');
        }

        userState.setProfileImagePath(path);

        notify('Image uploaded', SnackType.success);
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
      notify('Error updating profile picture', SnackType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> deleteConfirmationDialog(BuildContext context) async {
    final deleteKey = 'DELETE';

    final controller = TextEditingController();
    final focusNode = FocusNode();

    Future<void> closeKeyboard() async {
      FocusManager.instance.primaryFocus?.unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    FocusScope.of(context).unfocus();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => PopScope(
          onPopInvokedWithResult: (didPop, result) async {
            await closeKeyboard();
          },
          child: AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Delete Account',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  const Text(
                    'This action is irreversible. All your data will be permanently deleted.',
                  ),
                  const SizedBox(height: 12),
                  Text("Type '$deleteKey' in ALL CAPS to confirm:"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Type here...',
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) async {
                      if (controller.text.trim() == deleteKey) {
                        await closeKeyboard();
                        if (context.mounted) Navigator.of(context).pop(true);
                      }
                    },
                  ),
                  SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              await closeKeyboard();
                              if (context.mounted) Navigator.of(context).pop(false);
                            },
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (controller.text.trim() == deleteKey) {
                                await closeKeyboard();
                                if (context.mounted) Navigator.of(context).pop(true);
                              } else {
                                notify("Please enter 'DELETE' in all caps", SnackType.error);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Delete'),
                          ),
                        ),
                      ]
                    )
                  )
                ],
              ),
            ),
          ),
        )
      )
    );

    controller.dispose();
    focusNode.dispose();

    return result ?? false;
  }

  Future<String> deleteAccount(BuildContext context) async {
    final confirm = await deleteConfirmationDialog(context);
    if (!confirm) return 'Canceled';
    try {
      final res = await Supabase.instance.client.functions.invoke('delete-user');
      if (res.status == 200) {
        if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
        return '';
      }
      return 'Failed (${res.status})';
    } on FunctionException catch (e) {
      return e.reasonPhrase ?? 'Delete failed';
    } catch (_) {
      return 'Delete failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    final user = userState.user;

    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(title: const Text('Manage Account')),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () => _handleImagePick(userState),
                        child: (user.profileImagePath != null && user.profileImagePath!.isNotEmpty)
                          ? CircleAvatar(
                              radius: 70,
                              backgroundImage: CachedNetworkImageProvider(user.thumbUrl),
                            )
                          : CircleAvatar(
                              radius: 70,
                              backgroundColor: Colors.grey[200],
                              child: const Icon(Icons.person, size: 80, color: Colors.grey),
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    ListTile(
                      leading: const Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      trailing: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w300, fontSize: 18)),
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
                            notify('Name updated', SnackType.success);
                          } catch (e) {
                            notify('Error updating name.', SnackType.error);
                          }
                        }
                      },
                    ),

                    ListTile(
                      leading: const Text('Username', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      trailing: Text(user.username, style: const TextStyle(fontWeight: FontWeight.w300, fontSize: 18)),
                      onTap: () async {
                        final newUsername = await textFieldEditDialog(
                          context: context,
                          title: 'Edit Username',
                          initalValue: user.username,
                          maxLength: Constants.maxUsernameLength,
                          maxLines: 1,
                          validator: Validators.validateUsername,
                          asyncValidator: (username) async {
                            final exists = await userState.usernameExists(username);
                            return exists ? 'Username is taken' : null;
                          },
                        );
                        if (newUsername != null && newUsername != user.username) {
                          try {
                            await userState.setUsername(newUsername);
                            notify('Username updated', SnackType.success);
                          } catch (e) {
                            notify('Error updating username.', SnackType.error);
                          }
                        }
                      },
                    ),

                    ListTile(
                      leading: const Text('Bio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      trailing: Text(
                        (user.bio != null && user.bio!.isNotEmpty)
                            ? (user.bio!.length > 10 ? '${user.bio!.substring(0, 10)}...' : user.bio!)
                            : 'Add bio',
                        style: const TextStyle(fontWeight: FontWeight.w300, fontSize: 18),
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
                            notify('Bio updated', SnackType.success);
                          } catch (e) {
                            notify('Error updating bio.', SnackType.error);
                          }
                        }
                      },
                    ),

                    ListTile(
                      leading: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      trailing: Icon(Icons.lock, color: Colors.black.withOpacity(0.6)),
                      onTap: () => changePasswordDialog(context),
                    ),

                    const SizedBox(height: 8),

                    ListTile(
                      leading: const Icon(Icons.file_download_outlined),
                      title: const Text('Export my data'),
                      subtitle: const Text('Copy a JSON export to clipboard'),
                      onTap: () async {
                        final res = await exportMyData(context); // your helper
                        if (res == true) notify('Export copied!', SnackType.success);
                      },
                    ),
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
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final res = await deleteAccount(context);
                      if (res.isNotEmpty) notify(res, SnackType.error);
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
              color: Colors.black.withOpacity(0.1),
              child: const Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}