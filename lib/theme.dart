import 'package:flutter/material.dart';

class MineLoveTheme {
  // Colors
  static const Color deepMidnight = Color(0xFF090B14);
  static const Color secondaryDark = Color(0xFF101624);
  static const Color surface = Color(0xFF161C2E);
  static const Color surfaceElevated = Color(0xFF1B2235);
  static const Color loveRed = Color(0xFFFF4D6D);
  static const Color softPink = Color(0xFFFF7DAF);
  static const Color neonBlue = Color(0xFF6EA8FF);
  static const Color glowBlue = Color(0xFF8EC5FF);
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFC7D0E0);
  static const Color mutedText = Color(0xFF8E99B3);

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [loveRed, softPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const secondaryGradient = LinearGradient(
    colors: [neonBlue, Color(0xFFB6D2FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const romanticGlowGradient = LinearGradient(
    colors: [neonBlue, loveRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glow Effects
  static List<BoxShadow> redGlow = [
    BoxShadow(
      color: loveRed.withValues(alpha: 0.35),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> blueGlow = [
    BoxShadow(
      color: neonBlue.withValues(alpha: 0.28),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> softGlow = [
    BoxShadow(
      color: glowBlue.withValues(alpha: 0.16),
      blurRadius: 30,
      spreadRadius: 0,
    ),
  ];
}
