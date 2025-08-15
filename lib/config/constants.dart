import 'package:flutter/material.dart';

class Constants {
  static const Map<String, MaterialColor> themeMap = {
    'Grey': Colors.grey,
    'Cyan': Colors.cyan,
    'Orange': Colors.orange,
    'Pink': Colors.pink,
    'Red': Colors.red,
    'Purple': Colors.purple,
    'Green': Colors.green,
    'Indigo': Colors.indigo,
    'Teal': Colors.teal,
    'Deep Purple': Colors.deepPurple,
    'Brown': Colors.brown,
  };

  static MaterialColor getThemeColor(String slug) =>
      themeMap[slug] ?? Colors.grey;

  static const defaultGridColumns = 2;
  static const defaultTheme = 'grey';
  static const heartColor = Color(0xFFE49B9B);
  static const starColor = Color(0xFFF8EE9B);
  static final badgeBgColor = Colors.grey.shade300;
  static const TextStyle emptyListTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.grey,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w400
  );
  static const TextStyle badgeLabelStyle = TextStyle(fontSize: 10, color: Colors.white);

  static const int maxFileSize = 10 * 1024 * 1024;
  static const int defaultFeedLimit = 50;
  static const int defaultGalleryLimit = 20;
  static const int snackBarDuration = 1900; // milliseconds

  static const int maxUsernameLength = 20;
  static const int maxNameLength = 40;
  static final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
  static final emailRegex = RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
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