import 'package:flutter/material.dart';
import '../models/drink_form_data.dart';
import '../rating_picker.dart';

class AddOrEditDrinkDialog extends StatefulWidget {
  final DrinkFormData? initialData;
  final void Function(DrinkFormData) onSubmit;

  const AddOrEditDrinkDialog({
    super.key,
    this.initialData,
    required this.onSubmit,
  });

  @override
  State<AddOrEditDrinkDialog> createState() => _AddOrEditDrinkDialogState();
}

class _AddOrEditDrinkDialogState extends State<AddOrEditDrinkDialog> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  double _rating = 0;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?.name ?? '');
    _notesController = TextEditingController(text: widget.initialData?.notes ?? '');
    _rating = widget.initialData?.rating ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        DrinkFormData(
          name: _nameController.text.trim(),
          rating: _rating,
          notes: _notesController.text.trim(),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      contentPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Drink Name'),
              validator: (val) => val == null || val.isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),
            const Text('Rating', style: TextStyle(fontWeight: FontWeight.bold)),
            RatingPicker(
              rating: _rating,
              onChanged: (val) => setState(() => _rating = val),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              keyboardType: TextInputType.multiline,
              maxLines: null,
              minLines: 2,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleSubmit,
                  child: Text(widget.initialData == null ? 'Add' : 'Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
