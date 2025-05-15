import 'package:flutter/material.dart';
import 'add_shop_page.dart';

void main() => runApp(BobadexApp());

class BobadexApp extends StatelessWidget {
  const BobadexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bobadex',
      theme: ThemeData(primarySwatch: Colors.brown),
      home: HomePage(),
    );
  }
}

class Shop {
  final String name;
  final double rating;

  Shop({required this.name, required this.rating});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Shop> _shops = [];

  void _addShop(Shop shop) {
    setState(() {
      _shops.add(shop);
    });
  }

  void _navigateToAddShop() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddShopPage()),
    );

    if (result != null && result is Shop) {
      _addShop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Bobadex')),
      body: _shops.isEmpty
      ? const Center(child: Text('No shops yet. Tap + to add!'))
      : GridView.builder(
        itemCount: _shops.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final shop = _shops[index];
          return Card(
            elevation: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(child: Text(shop.name[0])),
                const SizedBox(height: 8),
                Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Rating: ${shop.rating.toStringAsFixed(1)}'),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddShop,
        child: const Icon(Icons.add),
      ),
    );
  }
}
