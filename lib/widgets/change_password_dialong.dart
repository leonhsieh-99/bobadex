import 'package:bobadex/helpers/show_snackbar.dart';
import 'package:bobadex/state/notification_queue.dart';
import 'package:bobadex/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> changePasswordDialog(BuildContext context) async {
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? currentPasswordError;
  bool _isLoading = false;

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => Stack(
        children: [
          AlertDialog(
            title: Text('Change Password'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Current password',
                        errorText: currentPasswordError,
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Enter current password' : null,
                    ),
                    TextFormField(
                      controller: newController,
                      obscureText: true,
                      decoration: InputDecoration(hintText: 'New password'),
                      validator: Validators.validatePassword,
                    ),
                    TextFormField(
                      controller: confirmController,
                      obscureText: true,
                      decoration: InputDecoration(hintText: 'Confirm password'),
                      validator: (val) => val == newController.text ? null : 'Passwords do not match',
                    ),
                  ],
                ),
              )
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  
                  if (!formKey.currentState!.validate()) return;
                  setState(() => _isLoading = true);

                  final current = currentController.text.trim();
                  final newPass = newController.text.trim();

                  try {
                    final  user = Supabase.instance.client.auth.currentUser;
                    final email = user?.email;

                    if (email == null) throw Exception('No email found');

                    // Re-authenticate
                    try {
                      await Supabase.instance.client.auth.signInWithPassword(
                        email: email,
                        password: current
                      );
                    } catch (e) {
                      setState(() => currentPasswordError = 'Current password incorrect');
                      return;
                    }

                    // Update password
                    await Supabase.instance.client.auth.updateUser(
                      UserAttributes(password: newPass),
                    );

                    if (context.mounted) {
                      context.read<NotificationQueue>().queue('Password changed successfully', SnackType.success);
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      context.read<NotificationQueue>().queue('Error changing password', SnackType.error);
                    }
                  } finally {
                    setState(() => _isLoading = false);
                  }
                },
                child: const Text('Save'),
              )
            ],
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
      ),
    )
  );
}