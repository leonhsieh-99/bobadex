import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OnboardingGate extends StatelessWidget {
  final Widget child;               // your existing body content
  final VoidCallback onAddShop;
  final bool isCurrentUser;

  const OnboardingGate({
    super.key,
    required this.child,
    required this.onAddShop,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCurrentUser) return child;

    final wizardDone =
        context.select<UserState, bool>((s) => s.current.onboarded == true);
    if (!wizardDone) return child;

    final shopsCount =
        context.select<ShopState, int>((s) => s.shopsForCurrentUser().length);

    final showFirstRun = (shopsCount == 0);
    if (!showFirstRun) return child;

    return Stack(
      children: [
        child,
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: FirstRunCard(onAddShop: onAddShop),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class FirstRunCard extends StatelessWidget {
  final VoidCallback onAddShop;
  const FirstRunCard({super.key, required this.onAddShop});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to Bobadex 👋',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start building your collection by adding your first shop.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add your first shop'),
                onPressed: onAddShop,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

