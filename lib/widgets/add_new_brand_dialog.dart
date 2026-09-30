import 'package:bobadex/brand/brand_request.dart';
import 'package:bobadex/models/city.dart';
import 'package:bobadex/state/city_data_provider.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:provider/provider.dart';

class AddNewBrandDialog extends StatefulWidget {
  final Future<String?> Function(BrandRequestDraft draft) onSubmit;
  final List<City>? cities;
  const AddNewBrandDialog({super.key, required this.onSubmit, this.cities});

  @override
  State<AddNewBrandDialog> createState() => _AddNewBrandDialogState();
}

class _AddNewBrandDialogState extends State<AddNewBrandDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _urlController = TextEditingController();
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
    _addressController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    final seeded = widget.cities;
    if (seeded != null) {
      setState(() => _cities = seeded);
      return;
    }
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
        .where(
          (city) =>
              city.name.toLowerCase().contains(pattern) ||
              city.state.toLowerCase().contains(pattern),
        )
        .take(10);
  }

  @override
  Widget build(BuildContext context) {
    final helperStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: context.boba.inkMuted, height: 1.35);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: BobaSpace.x6,
        vertical: BobaSpace.x6,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BobaSpace.x6,
          BobaSpace.x6,
          BobaSpace.x6,
          BobaSpace.x5,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Request a brand',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: BobaSpace.x5),
                if (_isSubmitting) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: BobaSpace.x4),
                ],
                TextFormField(
                  key: const Key('brand-request-name'),
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Brand name'),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.isEmpty || name.length > 160) {
                      return 'Enter a brand name up to 160 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: BobaSpace.x4),
                Autocomplete<City>(
                  displayStringForOption: _cityLabel,
                  optionsBuilder: _cityOptions,
                  onSelected: (City city) {
                    setState(() => _selectedCity = city);
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          key: const Key('brand-request-city'),
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'City, State',
                          ),
                          validator: (_) =>
                              _selectedCity == null ? 'Select a city' : null,
                          onFieldSubmitted: (_) => onFieldSubmitted(),
                          onChanged: (value) {
                            final selected = _selectedCity;
                            if (selected != null &&
                                value != _cityLabel(selected)) {
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
                const SizedBox(height: BobaSpace.x4),
                TextFormField(
                  key: const Key('brand-request-address'),
                  controller: _addressController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Storefront address',
                    helperText:
                        'Optional. Add the street address if you know the specific location.',
                    helperMaxLines: 2,
                    helperStyle: helperStyle,
                  ),
                  validator: (value) {
                    final street = value?.trim() ?? '';
                    if (street.length > 300) return 'That address is too long.';
                    return null;
                  },
                ),
                const SizedBox(height: BobaSpace.x5),
                TextFormField(
                  key: const Key('brand-request-url'),
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'Website or social link',
                    helperText: 'Optional. One http or https link.',
                    helperStyle: helperStyle,
                  ),
                  validator: (value) {
                    final url = value?.trim() ?? '';
                    if (url.isEmpty) return null;
                    if (!RegExp(
                      r'^https?://\S+$',
                      caseSensitive: false,
                    ).hasMatch(url)) {
                      return 'Use one http or https link.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: BobaSpace.x6),
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          if (_isSubmitting) return;
                          if (_formKey.currentState?.validate() != true ||
                              _selectedCity == null) {
                            return;
                          }
                          final city = _selectedCity!;
                          setState(() => _isSubmitting = true);
                          final error = await widget.onSubmit(
                            BrandRequestDraft(
                              name: _nameController.text,
                              city: city.name,
                              state: city.state,
                              address: _addressController.text,
                              sourceUrl: _urlController.text,
                            ),
                          );
                          if (!mounted) return;
                          setState(() => _isSubmitting = false);
                          if (context.mounted) {
                            Navigator.of(context).pop(error ?? 'success');
                          }
                        },
                  child: const Text('Submit'),
                ),
                const SizedBox(height: BobaSpace.x4),
                Text(
                  'City and state data provided by https://simplemaps.com/data/us-cities',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.boba.inkFaint,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
