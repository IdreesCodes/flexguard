import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Premium Blue palette
  static const Color primaryBlue = Color(0xFF2166F3); // royal blue
  static const Color accentBlue = Color(0xFFF2F6FF); // soft backdrop
  static const Color darkText = Color(0xFF0E1B2A); // deep navy text
  static const Color subtleText = Color(0xFF5B6B7C); // muted slate
  static const Color successGreen = Color(0xFF16A34A);
  static const Color warningRed = Color(0xFFDC2626);
}

class Insets {
  Insets._();

  static const double xs = 6;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
}

class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 600);
}

class Radii {
  Radii._();

  static const BorderRadius md = BorderRadius.all(Radius.circular(18));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(28));
}

enum TransactionType { expense, income, savings }


