import 'package:flutter/material.dart';

void main() => runApp(BobadexApp());

class BobadexApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bobadex',
      theme: ThemeData(primarySwatch: Colors.brown),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  final List<String> bobaShops = ['Tiger Sugar', 'Boba Guys', 'Gong Cha'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Bobadex')),
      body: ListView.builder(
        itemCount: bobaShops.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(bobaShops[index]),
            leading: CircleAvatar(child: Text(bobaShops[index][0])),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Next: Show form to add a new boba shop
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
