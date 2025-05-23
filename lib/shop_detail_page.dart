import 'package:bobadex/models/drink_form_data.dart';
import 'package:bobadex/models/shop.dart';
import 'package:bobadex/rating_picker.dart';
import 'package:flutter/material.dart';
import 'models/drink.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopDetailPage extends StatefulWidget{
  final Shop shop;
  const ShopDetailPage({super.key, required this.shop});

  @override
  State<ShopDetailPage> createState() => _ShopDetailPage();
}

class _ShopDetailPage extends State<ShopDetailPage> {
  final supabase = Supabase.instance.client;
  List<Drink> _drinks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDrinks();
  }
  
  Future<void> _openDrinkDialog({
    DrinkFormData? initalData,
    required void Function(DrinkFormData) onSubmit,
  }) async {
    final nameController = TextEditingController(text: initalData?.name ?? '');
    double rating = initalData?.rating ?? 0;
    final formkey = GlobalKey<FormState>();
    print(initalData);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        contentPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Form(
          key: formkey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Drink Name'),
                validator: (val) => val == null || val.isEmpty ? 'Enter a name' : null,
              ),
              SizedBox(height: 12),
              const Text('Rating', style: TextStyle(fontWeight: FontWeight.bold)),
              StatefulBuilder(
                builder: (context, setState) {
                  return RatingPicker(
                    rating: rating,
                    onChanged: (val) => setState(() => rating = val),
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (formkey.currentState!.validate()) {
                        onSubmit(DrinkFormData(
                          name: nameController.text.trim(),
                          rating: rating,
                        ));
                        Navigator.pop(context);
                      }
                    },
                    child: Text(initalData == null ? 'Add' : 'Update'),
                  ),
                ],
              )
            ],
          ),
        )
      )
    );
  }

  Future<void> _loadDrinks() async {
    print('loading drinks');
    setState(() {
      _isLoading = true;
    });
    try {
      print(widget.shop.id);
      final response = await supabase
        .from('drinks')
        .select()
        .eq('shop_id', widget.shop.id);

        final data = response as List;
        print(data);
        setState(() {
          _drinks = data.map((json) => Drink.fromJson(json)).toList();
        });
    } catch (e) {
      print('Failed to load drinks: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.shop.name)),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                //TODO: Navigate to gallery
              },
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  (widget.shop.imageUrl == null || widget.shop.imageUrl!.isEmpty)
                    ? Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(Icons.store, size: 64, color: Colors.white70)
                      ),
                    )
                    : Image.network(
                      widget.shop.imageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 64, color: Colors.white70)
                          ),
                        );
                      },
                    ),
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.shop.name,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('⭐ ${widget.shop.rating.toStringAsFixed(1)}',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: _drinks.length,
                itemBuilder: (context, index) {
                  final drink = _drinks[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        title: Text(
                          drink.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text('⭐ ${drink.rating}'),
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('No notes yet...'), // replace later
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              _openDrinkDialog(
                                initalData: 
                                  DrinkFormData(
                                    name: drink.name,
                                    rating: drink.rating
                                  ),
                                onSubmit: (updatedDrink) async {
                                  await supabase.from('drinks').update({
                                    'name': updatedDrink.name,
                                    'rating': updatedDrink.rating,
                                  })
                                  .eq('id', drink.id);
                                  _loadDrinks();
                                }
                              );
                            },
                            child: Text('Edit'),
                          ),
                        ],
                      ),
                    ),
                  );
                })
            ),
          ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _openDrinkDialog(
            onSubmit: (drink) async {
              await supabase.from('drinks').insert({
                'shop_id': widget.shop.id,
                'user_id': supabase.auth.currentUser!.id,
                'name': drink.name,
                'rating': drink.rating
              });
            },
          );
          _loadDrinks();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
