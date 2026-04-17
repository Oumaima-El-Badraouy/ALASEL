import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Thème AL ASEL : [El Messiri] pour les titres (esprit Maghreb), [Cairo] pour le corps.
class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.deepBlue,
        primary: AppColors.deepBlue,
        onPrimary: AppColors.white,
        secondary: AppColors.terracotta,
        onSecondary: AppColors.white,
        tertiary: AppColors.gold,
        surface: AppColors.parchment,
        onSurface: AppColors.ink,
        error: const Color(0xFFB42318),
      ),
      scaffoldBackgroundColor: AppColors.sand,
    );

    final cairo = GoogleFonts.cairoTextTheme(base.textTheme);
    final textTheme = cairo.copyWith(
      displayLarge: GoogleFonts.elMessiri(textStyle: cairo.displayLarge, fontWeight: FontWeight.w700, color: AppColors.ink),
      displayMedium: GoogleFonts.elMessiri(textStyle: cairo.displayMedium, fontWeight: FontWeight.w700, color: AppColors.ink),
      displaySmall: GoogleFonts.elMessiri(textStyle: cairo.displaySmall, fontWeight: FontWeight.w700, color: AppColors.ink),
      headlineLarge: GoogleFonts.elMessiri(textStyle: cairo.headlineLarge, fontWeight: FontWeight.w700, color: AppColors.deepBlue),
      headlineMedium: GoogleFonts.elMessiri(textStyle: cairo.headlineMedium, fontWeight: FontWeight.w700, color: AppColors.deepBlue),
      headlineSmall: GoogleFonts.elMessiri(textStyle: cairo.headlineSmall, fontWeight: FontWeight.w600, color: AppColors.deepBlue),
      titleLarge: GoogleFonts.elMessiri(textStyle: cairo.titleLarge, fontWeight: FontWeight.w600, color: AppColors.deepBlue),
      titleMedium: GoogleFonts.elMessiri(textStyle: cairo.titleMedium, fontWeight: FontWeight.w600, color: AppColors.deepBlue),
      titleSmall: GoogleFonts.cairo(textStyle: cairo.titleSmall, fontWeight: FontWeight.w700, color: AppColors.ink),
      bodyLarge: GoogleFonts.cairo(textStyle: cairo.bodyLarge, height: 1.45),
      bodyMedium: GoogleFonts.cairo(textStyle: cairo.bodyMedium, height: 1.4),
      bodySmall: GoogleFonts.cairo(textStyle: cairo.bodySmall, color: AppColors.muted),
      labelLarge: GoogleFonts.cairo(textStyle: cairo.labelLarge, fontWeight: FontWeight.w700),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        backgroundColor: AppColors.parchment,
        foregroundColor: AppColors.deepBlue,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.elMessiri(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.deepBlue,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.35), width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        labelStyle: GoogleFonts.cairo(color: AppColors.muted, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.deepBlue.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.deepBlue.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.deepBlue,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepBlue,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepBlue,
          side: BorderSide(color: AppColors.deepBlue.withValues(alpha: 0.45)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.terracotta,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.gold.withValues(alpha: 0.28),
        labelStyle: GoogleFonts.cairo(color: AppColors.ink, fontWeight: FontWeight.w600),
        side: BorderSide(color: AppColors.deepBlue.withValues(alpha: 0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.parchment,
        elevation: 8,
        shadowColor: AppColors.deepBlue.withValues(alpha: 0.12),
        height: 72,
        indicatorColor: AppColors.gold.withValues(alpha: 0.38),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final sel = s.contains(WidgetState.selected);
          return GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
            color: sel ? AppColors.deepBlue : AppColors.muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((s) {
          final sel = s.contains(WidgetState.selected);
          return IconThemeData(color: sel ? AppColors.deepBlue : AppColors.muted, size: 24);
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.parchment,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.deepBlue,
        contentTextStyle: GoogleFonts.cairo(color: AppColors.white, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: AppColors.gold.withValues(alpha: 0.25), thickness: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.terracotta),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.deepBlue,
        titleTextStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: AppColors.ink),
      ),
    );
  }
}
