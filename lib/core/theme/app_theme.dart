import 'package:flutter/material.dart';

class AppTheme {
  static const kWhiteColor = Colors.white;
  static const kBlackColor = Color(0xFF172033);
  static const kBlueColor = Color(0xFF1769E0);
  static const kRedColor = Color(0xFFE5484D);
  static const kGreenColor = Color(0xFF18A871);
  static const kOrangeColor = Color(0xFFF49B22);
  static const kAuthColor = Color(0xFFF5F8FC);
  static const kSurfaceColor = Color(0xFFF8FAFC);
  static const kMutedColor = Color(0xFF64748B);
  // Kept as named surfaces for the OTP screen and future authentication flows.
  static const appColor1 = Color(0xFFE2E8F0);
  static const appColor2 = kWhiteColor;

  static final ThemeData themeData = ThemeData(
    useMaterial3: true,
    fontFamily: 'Lato',
    colorScheme: ColorScheme.fromSeed(
      seedColor: kBlueColor,
      primary: kBlueColor,
      surface: kSurfaceColor,
    ),
    scaffoldBackgroundColor: kSurfaceColor,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 15, color: kBlackColor),
      titleMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kBlackColor),
      titleLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: kBlackColor),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kWhiteColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kBlueColor, width: 1.5)),
    ),
  );
}
