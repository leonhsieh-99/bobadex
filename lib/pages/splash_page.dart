import 'dart:math';
import 'package:flutter/material.dart';

const List<String> funFacts = [
  "All tea comes from one plant: Camellia sinensis. The differences between green, black, oolong, and white teas come from how the leaves are processed after harvesting.",
  "Camellia sinensis has two main varietals: sinensis (Chinese) and assamica (Indian/Assam). Both make all kinds of tea!",
  "Black tea is fully oxidized, while green tea is not oxidized at all. Oolong is partially oxidized.",
  "Tea was discovered in China over 4,000 years ago—according to legend, when leaves blew into Emperor Shen Nong's boiling water.",
  "Matcha is made from finely ground, shade-grown green tea leaves.",
  "Boba pearls are made from tapioca starch, which comes from the cassava root.",
  "The first milk tea shop is believed to be Chun Shui Tang in Taichung, Taiwan, in the 1980s.",
  "Classic boba milk tea is made with black tea, milk, sweetener, and chewy tapioca pearls.",
  "The 'bubbles' in bubble tea originally referred to the frothy bubbles formed when the drink was shaken—not the pearls themselves!",
  "Cheese foam, a creamy, slightly salty topping, is a trendy addition to tea drinks.",
  "Taro is a root vegetable that gives bubble tea its signature purple color and nutty flavor."
  "In 2019, Taiwan set the record with a cup of bubble tea that held over 22,000 liters (about 5,800 gallons).",
  "Black pearls get their color from brown sugar or caramel. Clear pearls are the default, and you can find green tea, mango, or popping boba (filled with fruit juice).",
  "The 🧋 emoji was added to Unicode in 2020 thanks to a campaign by milk tea fans!",
  "April 30 is officially “National Bubble Tea Day” in the US.",
  "There’s an online movement called the “Milk Tea Alliance”—a meme-based, pro-democracy internet community named after the popularity of milk tea across Taiwan, Hong Kong, Thailand, and more.",
  "Called “trà sữa,” milk tea exploded in popularity in Vietnam over the past decade. Some shops serve unique toppings like flan, grass jelly, or even mochi cubes.",
  "“Yuan yang” (鸳鸯, meaning “mandarin ducks”) is a popular drink that mixes milk tea and coffee in one cup. It’s both rich and highly caffeinated!",
  "Globally, the bubble tea market is projected to exceed \$6 billion by 2027.",
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
