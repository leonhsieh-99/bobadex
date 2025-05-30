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

  static const defaultGridColumns = 3;
  static const defaultTheme = 'grey';
  static const heartColor = Color(0xFFE49B9B);
  static const starColor = Color(0xFFF8EE9B);
}
