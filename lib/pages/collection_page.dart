import 'package:bobadex/ui/components/empty_state.dart';
import 'package:flutter/material.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: EmptyState(
          title: 'Collections coming soon',
          body:
              'Regional collections will live here once location data is ready.',
        ),
      ),
    );
  }
}
