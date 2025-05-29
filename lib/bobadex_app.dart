import 'package:flutter/material.dart';
import 'app_initializer.dart';

class BobadexApp extends StatelessWidget {
  const BobadexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppInitializer(); // handles session, theming, routing
  }
}
