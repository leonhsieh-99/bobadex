import 'package:bobadex/models/city.dart';
import 'package:bobadex/state/city_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';

class AddNewBrandDialog extends StatefulWidget {
  final void Function(String name, String location) onSubmit;
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
  final _locationController = TextEditingController();
  List<City>? _cities;

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
                TextFormField(
                  controller: _nameController,
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
                    _locationController.text = '${city.name}, ${city.state}';
                  },
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: _locationController,
                      focusNode: focusNode,
                      decoration: InputDecoration(labelText: 'City, State'),
                    );
                  },
                  emptyBuilder: (context) => ListTile(title: Text('No city found')),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.onSubmit(_nameController.text, _locationController.text);
                    }
                    if (mounted) Navigator.of(context).pop();
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