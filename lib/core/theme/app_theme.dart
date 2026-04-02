import 'package:flutter/material.dart';

class AppTheme {
  static Color appColor1 = Colors.grey.shade300;
  static Color appColor2 = Colors.grey.shade200;

  static Color kWhiteColor = Colors.white;
  static Color kBlackColor = Colors.black;
  static Color kBlueColor = Colors.blue;
  static Color kRedColor = Colors.red;
  static Color kGreenColor = Colors.green;
  static Color kOrangeColor = const Color.fromARGB(255, 255, 186, 59);

  static ThemeData themeData = ThemeData(
    textTheme: TextTheme(
      bodyMedium: TextStyle(
        fontSize: 18.0,
      ),
      titleMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: kWhiteColor,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Color.fromRGBO(36, 149, 255, 1),
    ),
  );
}
