import 'package:flutter/material.dart';

class AppTheme {
  static Color appColor1 = Colors.grey.shade300;
  static Color appColor2 = Colors.grey.shade200;

  static Color kWhiteColor = Colors.white;
  static Color kBlackColor = Colors.black;

  static ThemeData themeData = ThemeData(
    textTheme: TextTheme(
      bodyMedium: TextStyle(
        fontSize: 18.0,
      ),
    ),
  );
}
