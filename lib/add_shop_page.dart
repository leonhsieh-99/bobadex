import 'package:flutter/material.dart';
import 'main.dart';

class AddShopPage extends StatefulWidget {
  const AddShopPage({super.key});

  @override
  State<AddShopPage> createState() => _AddShopPageState();
}

class _AddShopPageState extends State<AddShopPage> {
  final _formkey = GlobalKey<FormState>();
  final _nameComtroller = TextEditingController();
  final _ratingController = TextEditingController();

  void _submit() {
    if (_formkey.currentState!.validate()) {
      final shop = Shop(
        name: _nameComtroller.text.trim(),
        rating: double.parse(_ratingController.text),
      );
      Navigator.pop(context, shop);
    }
  }

  @override
  void dispose() {
    _nameComtroller.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Boba Shop')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formkey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameComtroller,
                decoration: const InputDecoration(labelText: 'Shop Name'),
                validator: (value) => 
                  value == null || value.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ratingController,
                decoration: const InputDecoration(labelText: 'Rating (0-5)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final num = double.tryParse(value ?? '');
                  if (num == null || num < 0 || num > 5) {
                    return 'Enter a rating from 0 to 5';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Add Shop'
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}