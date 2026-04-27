import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand palette (from logo)
  static const Color purple = Color(0xFF79207D);       // deep purple — primary brand
  static const Color dustyGrape = Color(0xFF68549D);   // mid purple
  static const Color amethystSmoke = Color(0xFF8D79B1); // light purple

  // Primary — purple
  static const Color primary = purple;
  static const Color primaryLight = amethystSmoke;
  static const Color primaryDark = Color(0xFF561659);

  // Accent — sunflower gold
  static const Color accent = Color(0xFFF8B524);
  static const Color accentDark = Color(0xFFD99A10);

  // Backgrounds
  static const Color background = Color(0xFFF7F4FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFF3EFF9);

  // Text
  static const Color textPrimary = Color(0xFF1A0A1E);
  static const Color textSecondary = Color(0xFF68549D);
  static const Color textHint = Color(0xFFBDB3D4);

  // Status
  static const Color success = Color(0xFF78A237);   // sage green from logo
  static const Color error = Color(0xFFD83C36);     // scarlet rush from logo
  static const Color selected = Color(0xFF78A237);

  // Intelligence type colors — purple family + logo accents
  static const Color musical = Color(0xFFF8B524);       // sunflower gold
  static const Color linguistic = Color(0xFF79207D);    // purple
  static const Color logical = Color(0xFF68549D);       // dusty grape
  static const Color visual = Color(0xFF8D79B1);        // amethyst smoke
  static const Color kinesthetic = Color(0xFF561659);   // deep purple
  static const Color interpersonal = Color(0xFFD83C36); // scarlet rush
  static const Color intrapersonal = Color(0xFF9B3DA0); // purple mid
  static const Color naturalistic = Color(0xFF78A237);  // sage green

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, dustyGrape],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7F4FB), Color(0xFFEDE6F7)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDark],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, amethystSmoke],
  );

  static Map<String, Color> intelligenceColors = {
    'musical': musical,
    'linguistic': linguistic,
    'logical': logical,
    'visual': visual,
    'physical': kinesthetic,
    'interpersonal': interpersonal,
    'intrapersonal': intrapersonal,
    'naturalistic': naturalistic,
  };
}
