import 'package:bobadex/add_edit_drink_dialog.dart';
import 'package:bobadex/models/drink_form_data.dart';
import 'package:bobadex/models/shop.dart';
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
  final Set<String> _expandedDrinkIds = {};

  @override
  void initState() {
    super.initState();
    _loadDrinks();
  }

  Future<void> _loadDrinks() async {
    print('loading drinks');
    setState(() => _isLoading = true);
    try {
      print(widget.shop.id);
      final response = await supabase
        .from('drinks')
        .select()
        .eq('shop_id', widget.shop.id);

        final data = response as List;
        print(data);
        setState(() => _drinks = data.map((json) => Drink.fromJson(json)).toList());
    } catch (e) {
      print('Failed to load drinks: $e');
    } finally {
      setState(() => _isLoading = false);
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
                    child: Stack(
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ExpansionTile(
                            initiallyExpanded: _expandedDrinkIds.contains(drink.id),
                            onExpansionChanged: (isExpanded) { 
                              setState(() {
                                if (isExpanded) {
                                  _expandedDrinkIds.add(drink.id!);
                                } else {
                                  _expandedDrinkIds.remove(drink.id);
                                }
                              });
                            },
                            trailing: SizedBox.shrink(),
                            title: Row(
                              children: [
                                AnimatedRotation(
                                  turns: _expandedDrinkIds.contains(drink.id) ? 0.25 : 0.00,
                                  duration: const Duration(milliseconds: 200),
                                  child: const Icon(Icons.chevron_right, size: 20, color: Colors.brown),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    drink.name,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text('⭐ ${drink.rating}'),
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(12, 4, 12, 12),
                                  child: Text(
                                    drink.notes ?? 'No notes yet...',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                )
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AddOrEditDrinkDialog(
                                      initialData: DrinkFormData(
                                        name: drink.name,
                                        rating: drink.rating,
                                        notes: drink.notes,
                                      ),
                                      onSubmit: (updatedDrink) async {
                                        final response = await supabase
                                          .from('drinks')
                                          .update({
                                            'name': updatedDrink.name,
                                            'rating': updatedDrink.rating,
                                            'notes': updatedDrink.notes,
                                          })
                                          .eq('id', drink.id)
                                          .select()
                                          .single();
                                        
                                        if (response != null && context.mounted) {
                                          final updated = Drink.fromJson(response);
                                          setState(() => _drinks = _drinks.map((d) => d.id == updated.id ? updated : d).toList());
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to update drink.')),
                                          );
                                        }
                                      },
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(Icons.edit, size: 16),
                                ),
                              ),
                              InkWell(
                                onTap: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Drink'),
                                      content: const Text('Are you sure you want to remove this drink ?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                      ],
                                    )
                                  );
                                  if (confirm == true) {
                                    await supabase.from('drinks').delete().eq('id', drink.id);
                                    setState(() {
                                      _drinks.removeWhere((d) => d.id == drink.id);
                                    });
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(Icons.close, size: 16),
                                ),
                              ),
                            ],
                          )
                        ),
                      ],
                    ),
                  );
                })
            ),
          ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddOrEditDrinkDialog(
              onSubmit: (drink) async {
                final response = await supabase.from('drinks').insert({
                  'shop_id': widget.shop.id,
                  'user_id': supabase.auth.currentUser!.id,
                  'name': drink.name,
                  'rating': drink.rating,
                  'notes': drink.notes,
                })
                .select()
                .single();

                if (response != null && context.mounted) {
                  final newDrink = Drink.fromJson(response);
                  setState(() => _drinks.add(newDrink));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add drink.'))
                  );
                }
              },
            )
          );
        },
      ),
    );
  }
}
