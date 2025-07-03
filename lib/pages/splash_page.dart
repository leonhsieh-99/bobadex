import 'dart:math';
import 'package:flutter/material.dart';

const List<String> funFacts = [
  "All true tea comes from just one plant: Camellia sinensis. The differences between green, black, oolong, and white teas come from how the leaves are processed after harvesting.",
  "Camellia sinensis has two main varietals: sinensis (Chinese) and assamica (Indian/Assam). Both make all kinds of tea!",
  "Black tea is fully oxidized, while green tea is not oxidized at all. Oolong is partially oxidized.",
  "Tea was discovered in China over 4,000 years ago—according to legend, when leaves blew into Emperor Shen Nong's boiling water.",
  "Matcha is made from finely ground, shade-grown green tea leaves.",
  "Boba pearls are made from tapioca starch, which comes from the cassava root.",
  "The first bubble tea shop is believed to be Chun Shui Tang in Taichung, Taiwan, in the 1980s.",
  "Classic boba milk tea is made with black tea, milk, sweetener, and chewy tapioca pearls.",
  "The 'bubbles' in bubble tea originally referred to the frothy bubbles formed when the drink was shaken—not the pearls themselves!",
  "Cheese foam, a creamy, slightly salty topping, is a trendy addition to tea drinks.",
  "Taro is a root vegetable that gives bubble tea its signature purple color and nutty flavor."
];

class SplashPage extends StatelessWidget {
  SplashPage({super.key});

  final String randomFact = funFacts[Random().nextInt(funFacts.length)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // or your preferred color
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Placeholder
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.local_cafe, size: 56, color: Colors.deepPurple),
                ),
              ),
              const SizedBox(height: 32),
              // App Name
              const Text(
                'Bobadex',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 32),
              // Fun Fact
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.shade100.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.orangeAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          randomFact,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
