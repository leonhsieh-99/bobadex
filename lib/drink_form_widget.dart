// ---------------------Drink Widget------------------------
import 'package:flutter/material.dart';
import 'models/drink_form_data.dart';
import 'rating_picker.dart';

class DrinkFormWidget extends StatefulWidget{
  final void Function(DrinkFormData) onChanged;
  final VoidCallback? onRemove;
  final DrinkFormData? initalData;

  const DrinkFormWidget({
    super.key,
    required this.onChanged,
    this.onRemove,
    this.initalData,
  });

  @override
  State<DrinkFormWidget> createState() => DrinkFormWidgetState();
}

class DrinkFormWidgetState extends State<DrinkFormWidget> {
  final _formkey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  double _selectedRating = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initalData?.name ?? '');
    _selectedRating = widget.initalData?.rating ?? 0;
  }

  bool validate() {
    return _formkey.currentState?.validate() ?? false;
  }

  void _notifyParent() {
    widget.onChanged(DrinkFormData(
      name: _nameController.text.trim(),
      rating: _selectedRating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Form(
            key: _formkey,
            child: Column(
              children: [
                if (widget.onRemove != null)
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onRemove,
                    ),
                  ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Drink Name'),
                  onChanged: (_) => _notifyParent(),
                  validator: (value) => 
                    value == null || value.isEmpty ? 'Enter a name' : null,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text('Rating', style: Theme.of(context).textTheme.labelLarge),
                  ),
                ),
                RatingPicker(
                  rating: _selectedRating,
                  onChanged: (val) {
                    setState(() => _selectedRating = val);
                    _notifyParent();
                  },
                  filledIcon: Icons.circle,
                  halfIcon: Icons.adjust,
                  emptyIcon: Icons.circle_outlined,
                )
              ],
            ),
          )
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}