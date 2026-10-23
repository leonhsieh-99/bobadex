import 'package:bobadex/auth/local_account_cleanup.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const accountDeletedMessage = 'Account deleted';

String deleteFailureMessage({required int status, Object? details}) {
  final code = _errorCode(details);
  switch (code) {
    case 'unauthorized':
      return 'Your session expired. Sign in again, then retry deleting your account.';
    case 'storage_cleanup_failed':
    case 'cleanup_incomplete':
    case 'account_delete_failed':
    case 'auth_unavailable':
      return 'Could not finish deleting your account. Please try again.';
    case 'method_not_allowed':
      return 'Could not delete your account. Please try again.';
  }
  if (status == 401) {
    return 'Your session expired. Sign in again, then retry deleting your account.';
  }
  if (status == 503) {
    return 'Could not finish deleting your account. Please try again.';
  }
  return 'Could not delete your account. Please try again.';
}

String? _errorCode(Object? details) {
  if (details is Map) {
    for (final key in ['error', 'code', 'status']) {
      final value = details[key];
      if (value is String && value.isNotEmpty && value != 'ok') return value;
    }
  }
  if (details is String && details.isNotEmpty) return details;
  return null;
}

Future<bool> confirmAccountDeletion(BuildContext context) async {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  try {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Delete account',
            style: TextStyle(color: dialogContext.boba.danger),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'This permanently deletes your account and cannot be undone.',
              ),
              const SizedBox(height: 12),
              const Text("Type DELETE in all caps to confirm."),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'DELETE'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim() == 'DELETE') {
                  Navigator.of(dialogContext).pop(true);
                  return;
                }
                notify("Please enter 'DELETE' in all caps", SnackType.error);
              },
              child: Text(
                'Delete',
                style: TextStyle(color: dialogContext.boba.danger),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  } finally {
    controller.dispose();
    focusNode.dispose();
  }
}

/// Deletes the signed-in account. Returns an error message, or null on success.
/// Success copy is shown only after the server accepts the deletion.
Future<String?> deleteConfirmedAccount(BuildContext context) async {
  try {
    final res = await Supabase.instance.client.functions.invoke('delete-user');
    final data = res.data;
    final accepted = res.status == 200 && data is Map && data['status'] == 'ok';
    if (!accepted) {
      return deleteFailureMessage(status: res.status, details: data);
    }
  } on FunctionException catch (e) {
    return deleteFailureMessage(status: e.status, details: e.details);
  } catch (_) {
    return 'Could not delete your account. Please try again.';
  }

  if (context.mounted) await clearLocalAccount(context);
  notify(accountDeletedMessage, SnackType.info);
  return null;
}
