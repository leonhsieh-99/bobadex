import 'package:bobadex/models/tea_room.dart';
import 'package:flutter/material.dart';

class AddTeaRoomDialog extends StatefulWidget {
  final Function(TeaRoom) onSubmit;
  const AddTeaRoomDialog ({
    super.key,
    required this.onSubmit,
  });

  @override
  State<AddTeaRoomDialog> createState() => _AddTeaRoomDialogState();
}

class _AddTeaRoomDialogState extends State<AddTeaRoomDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Tea Room'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Room name',
                  ),
                  maxLength: 30,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Enter description (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    )
                  ),
                  maxLines: 4,
                  maxLength: 150,
                )
              ],
            ),
          )
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel')
        ),
        ElevatedButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              widget.onSubmit(
                TeaRoom(
                  id: '',
                  name: _nameController.text.trim(),
                  description: _descriptionController.text.trim(),
                  ownerId: ''
                )
              );
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add')
        ),
      ],
    );
  }
}