import 'package:flutter/material.dart';

Future<void> accountEditDialog ({
  required BuildContext context,
  required String title,
  required String initalValue,
  required Function(String) onSave,
  String? hintText,
  int? maxLength,
  FormFieldValidator<String>? validator,
  Future<String?> Function(String)? asyncValidator,
  int maxLines = 1,
}) async {
  final controller = TextEditingController(text: initalValue);
  final formKey = GlobalKey<FormState>();
  String? asyncError;

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hintText,
                    errorText: asyncError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: maxLines > 1
                      ? OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey),
                      )
                      : InputBorder.none,
                  ),
                  maxLength: maxLength,
                  maxLines: maxLines,
                  validator: validator,
                )
              ],
            )
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')
          ),
          ElevatedButton(
            onPressed: () async {
              final trimmedInput = controller.text.trim();

              if (trimmedInput == initalValue.trim()) {
                Navigator.pop(context);
                return;
              }

              setState(() => asyncError = null);
              if (!formKey.currentState!.validate()) return;
              if (asyncValidator != null) {
                final result = await asyncValidator(trimmedInput);
                if (result != null) {
                  setState(() => asyncError = result);
                  return;
                }
              }

              onSave(controller.text.trim());
              Navigator.pop(context);
            },
            child: Text('Save'),
          )
        ],
      )
    ), 
  );
}