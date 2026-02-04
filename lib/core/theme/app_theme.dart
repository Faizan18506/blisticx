import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Color Palette
  static const Color _obsidian = Color(0xFF121212);
  static const Color _charcoal = Color(0xFF1E1E1E);
  static const Color _gunmetal = Color(0xFF2C2C2C);
  static const Color _platinum = Color(0xFFE0E0E0);
  static const Color _electricBlue = Color(0xFF2979FF);
  // static const Color _crimson = Color(0xFFD50000); // For outliers/errors

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _obsidian,
      primaryColor: _electricBlue,
      colorScheme: const ColorScheme.dark(
        primary: _electricBlue,
        secondary: _electricBlue,
        surface: _charcoal,
        onSurface: _platinum,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: _platinum,
        displayColor: _platinum,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _obsidian,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _charcoal,
        selectedItemColor: _electricBlue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: _gunmetal,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: Colors.black45,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _electricBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}
