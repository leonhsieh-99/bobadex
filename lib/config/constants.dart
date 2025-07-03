import 'package:flutter/material.dart';

class Constants {
  static const Map<String, MaterialColor> themeMap = {
    'grey': Colors.grey,
    'cyan': Colors.cyan,
    'orange': Colors.orange,
    'pink': Colors.pink,
    'red': Colors.red,
    'purple': Colors.purple,
    'green': Colors.green,
    'indigo': Colors.indigo,
    'teal': Colors.teal,
    'deepPurple': Colors.deepPurple,
    'brown': Colors.brown,
  };

  static MaterialColor getThemeColor(String slug) =>
      themeMap[slug] ?? Colors.grey;

  static const defaultGridColumns = 2;
  static const defaultTheme = 'grey';
  static const heartColor = Color(0xFFE49B9B);
  static const starColor = Color(0xFFF8EE9B);
  static const TextStyle emptyListTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.grey,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w400
  );
  static const TextStyle badgeLabelStyle = TextStyle(fontSize: 10, color: Colors.white);

  // ------------- Fun facts for loading screen -----------------
  static const List<String> funFacts = [
    // Tea
    "All true tea comes from just one plant: Camellia sinensis. The differences between green, black, oolong, and white teas come from how the leaves are processed after harvesting.",
    "Black tea is fully oxidized, while green tea is not oxidized at all. Oolong is partially oxidized, which gives it a unique flavor profile.",
    "Tea was discovered in China over 4,000 years ago—according to legend, when leaves from a wild tree blew into Emperor Shen Nong's boiling water.",
    "Matcha is made from finely ground, shade-grown green tea leaves and is traditionally used in Japanese tea ceremonies.",
    // Boba/Milk Tea
    "Boba pearls are made from tapioca starch, which comes from the cassava root.",
    "The first bubble tea shop is believed to be Chun Shui Tang in Taichung, Taiwan, in the 1980s.",
    "Classic boba milk tea is made with black tea, milk, sweetener, and chewy tapioca pearls.",
    "The 'bubbles' in bubble tea originally referred to the frothy bubbles formed when the drink was shaken—not the pearls themselves!",
    // General Drink/Fun
    "Some shops use brown sugar syrup to give boba pearls extra flavor and a beautiful caramel color.",
    "Fruit teas often use real fruit purees or syrups, making them a refreshing alternative to milk-based drinks.",
    "Jelly toppings in bubble tea can be made from coconut, lychee, or konjac (a root vegetable).",
    "You can order boba drinks hot or iced—hot boba is especially popular in Taiwan during the winter.",
    "Boba straw sizes are wider to help slurp up the chewy pearls along with your drink.",
    "Cheese foam, a creamy, slightly salty topping, is a trendy addition to tea drinks in Asia and beyond.",
    "Taro is a root vegetable that gives bubble tea its signature purple color and a unique, nutty flavor."
];

}

class AppButtonStyles {
  static final ButtonStyle deleteButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 44),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  );
}