import 'package:bobadex/models/city.dart';
import 'package:bobadex/state/city_data_provider.dart';
import 'package:flutter/material.dart';
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
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    final cityProvider = context.read<CityDataProvider>();
    final loaded = await cityProvider.getCities();
    if (mounted) { 
      setState(() => _cities = loaded);
    }
  }

  String _cityLabel(City city) => '${city.name}, ${city.state}';

  Iterable<City> _cityOptions(TextEditingValue value) {
    final cities = _cities;
    if (cities == null || cities.isEmpty) return const Iterable<City>.empty();
    final pattern = value.text.toLowerCase().trim();
    if (pattern.isEmpty) return cities.take(10);
    return cities
      .where((city) =>
          city.name.toLowerCase().contains(pattern) ||
          city.state.toLowerCase().contains(pattern))
      .take(10);
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
                Autocomplete<City>(
                  displayStringForOption: _cityLabel,
                  optionsBuilder: _cityOptions,
                  onSelected: (City city) {
                    setState(() => _selectedCity = city);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(labelText: 'City, State'),
                      validator: (_) => _selectedCity == null ? 'Select a city' : null,
                      onFieldSubmitted: (_) => onFieldSubmitted(),
                      onChanged: (value) {
                        final selected = _selectedCity;
                        if (selected != null && value != _cityLabel(selected)) {
                          setState(() => _selectedCity = null);
                        }
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 240),
                          child: options.isEmpty
                            ? const ListTile(title: Text('No city found'))
                            : ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final city = options.elementAt(index);
                                  return ListTile(
                                    title: Text(_cityLabel(city)),
                                    onTap: () => onSelected(city),
                                  );
                                },
                              ),
                        ),
                      ),
                    );
                  },
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
