import 'package:flutter/material.dart';

/// Palette AL ASEL — inspiration riads, zellige Fassi, tadelakt, laiton et Atlas.
abstract class AppColors {
  /// Bleu nuit — portes, boiseries, navigation
  static const Color deepBlue = Color(0xFF152B45);
  static const Color deepBlueLight = Color(0xFF1C3D5A);

  /// Terre cuite — chaleur méditerranéenne / Marrakech
  static const Color terracotta = Color(0xFFB85C2E);
  static const Color terracottaLight = Color(0xFFD4784A);

  /// Sable & parchemin — murs tadelakt
  static const Color sand = Color(0xFFF6EFE6);
  static const Color sandDeep = Color(0xFFE9DDCF);
  static const Color parchment = Color(0xFFFDF8F3);

  /// Or / laiton — filets zellige
  static const Color gold = Color(0xFFC9A227);
  static const Color goldDark = Color(0xFF9A7B1A);
  static const Color goldMuted = Color(0xFFD4BC6A);

  /// Vert émail zellige (Fès)
  static const Color zellijGlaze = Color(0xFF2A6B6F);
  static const Color zellijMint = Color(0xFF3D8A8E);

  /// Bordeaux tapis / accent royal (optionnel)
  static const Color burgundy = Color(0xFF6B2D3C);

  static const Color ink = Color(0xFF1A1F2A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF6B6570);

  /// Dégradé fond écran (splash, auth)
  static const List<Color> sandGradient = [
    Color(0xFFF8F2EA),
    Color(0xFFEDE4D8),
    Color(0xFFE8DFD4),
  ];

  /// Accent pour indicateurs / succès
  static const Color oasis = Color(0xFF2D6A4F);
}
