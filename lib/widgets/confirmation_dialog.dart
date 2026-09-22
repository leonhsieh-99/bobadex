import 'package:flutter/material.dart';
import 'package:bobadex/ui/theme/boba_context.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String message,
  String title = "Confirm",
  String cancelText = "Cancel",
  String confirmText = "OK",
  Color? confirmColor,
}) async {
  final resolvedConfirmColor = confirmColor ?? context.boba.danger;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: resolvedConfirmColor,
          ),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}
