import 'package:bobadex/models/city.dart';
import 'package:bobadex/state/city_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';

class AddNewBrandDialog extends StatefulWidget {
  final Future<String?> Function(String name, City city) onSubmit;
  const AddNewBrandDialog ({
    super.key,
    required this.onSubmit,
  });

  @override
  State<AddNewBrandDialog> createState () => _AddNewBrandDialogState();
}

class _AddNewBrandDialogState extends State<AddNewBrandDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  City? _selectedCity;
  List<City>? _cities;
  TextEditingController? _cityFieldController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    final cityProvider = context.read<CityDataProvider>();
    final loaded = await cityProvider.getCities();
    if (mounted) { 
      setState(() => _cities = loaded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isSubmitting) LinearProgressIndicator(),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Brand name',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter a name' : null,
                ),
                TypeAheadField<City>(
                suggestionsCallback: (pattern) async {
                  return _cities!
                    .where((city) =>
                        city.name.toLowerCase().contains(pattern.toLowerCase()) ||
                        city.state.toLowerCase().contains(pattern.toLowerCase()))
                    .take(10)
                    .toList();
                  },
                  itemBuilder: (context, City city) {
                    return ListTile(
                      title: Text('${city.name}, ${city.state}'),
                    );
                  },
                  onSelected: (City city) {
                    setState(() {
                      _selectedCity = city;
                      _cityFieldController?.text = '${city.name}, ${city.state}';
                    });
                  },
                  builder: (context, controller, focusNode) {
                    _cityFieldController = controller;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(labelText: 'City, State'),
                    );
                  },
                  emptyBuilder: (context) => ListTile(title: Text('No city found')),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : () async {
                    if (_formKey.currentState?.validate() != true || _selectedCity == null) return;
                    setState(() => _isSubmitting = true);
                    final error = await widget.onSubmit(_nameController.text, _selectedCity!);
                    setState(() => _isSubmitting = false);
                    if (context.mounted) {
                      Navigator.of(context).pop(error ?? 'success');
                    }
                  },
                  child: Text('Submit'),
                ),
                SizedBox(height: 10),
                Text(
                  'City and state data provided by https://simplemaps.com/data/us-cities',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w300,
                    fontSize: 8,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}