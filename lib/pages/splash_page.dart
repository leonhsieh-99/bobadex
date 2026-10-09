import 'dart:math';
import 'package:bobadex/ui/components/boba_card.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

const List<String> funFacts = [
  "All tea comes from one plant, Camellia sinensis. Green, black, oolong, and white are just different ways of processing the leaf.",
  "Every tea leaf is really just Camellia sinensis var. sinensis or var. assamica. That’s the whole list.",
  "Legend says tea began when leaves fell into Emperor Shen Nong’s boiling water, more than 4,000 years ago.",
  "Matcha is shade-grown green tea, ground fine enough that you drink the whole leaf.",
  "Tapioca pearls come from cassava, a South American root that ended up at the bottom of a Taiwanese drink.",
  "Two shops in Taiwan still claim the first pearl milk tea: Chun Shui Tang in Taichung and Hanlin Tea Room in Tainan.",
  "The “bubbles” in bubble tea first meant the foam from shaking the drink, not the pearls.",
  "“Boba” started as the name for the big pearls. The smaller ones are just pearls.",
  "The compliment for a good pearl is QQ: chewy, springy, and a little bouncy.",
  "The straw is extra wide so the pearls can come along for the sip.",
  "Brown sugar stripes are syrup on the inside of the cup, not a flavor mixed into the tea.",
  "Popping boba isn’t tapioca. It’s a pocket of juice inside a thin gel skin.",
  "A salted cheese cap sounds wrong until you try it. The salt is what makes the sweet work.",
  "Basil seeds swell in the cup. That’s why shops call them frog eggs.",
  "Wintermelon tea is a syrup. The melon is simmered with sugar, then mixed into the drink.",
  "Hong Kong milk tea is poured through a cloth filter people nicknamed a silk stocking.",
  "Yuan yang, named for a pair of mandarin ducks, is milk tea and coffee in the same cup.",
  "The biggest cup of bubble tea on record held 680 liters. About 170 of those liters were pearls.",
  "The boba emoji arrived in 2020, after a campaign by milk tea fans.",
  "April 30 is National Bubble Tea Day.",
];

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final String randomFact;

  @override
  void initState() {
    super.initState();
    randomFact = funFacts[Random().nextInt(funFacts.length)];
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: Center(child: _SplashContent())),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_SplashPageState>()!;
    final fact = state.randomFact;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BobaSpace.x6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'lib/assets/logo.svg',
            width: 160,
            height: 160,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: BobaSpace.x7),
          BobaCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: context.boba.accent,
                ),
                const SizedBox(width: BobaSpace.x3),
                Expanded(
                  child: Text(
                    fact,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
