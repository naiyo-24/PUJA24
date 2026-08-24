import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.pujaRed,
      scaffoldBackgroundColor: AppColors.ivory,
      colorScheme: const ColorScheme.light(
        primary: AppColors.pujaRed,
        secondary: AppColors.antiqueGold,
        surface: AppColors.pureWhite,
        error: AppColors.errorRed,
      ),
      textTheme: _buildTextTheme(ThemeData.light().textTheme, AppColors.textPrimary, AppColors.textSecondary),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ivory,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pujaRed,
          foregroundColor: AppColors.pureWhite,
          elevation: 0,
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.pureWhite,
        elevation: 2,
        shadowColor: AppColors.border.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.pureWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.pujaRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.pujaRed,
      scaffoldBackgroundColor: AppColors.deepMaroon, // Use deep maroon for dark theme bg
      colorScheme: const ColorScheme.dark(
        primary: AppColors.pujaRed,
        secondary: AppColors.antiqueGold,
        surface: AppColors.charcoal,
        error: AppColors.errorRed,
      ),
      textTheme: _buildTextTheme(ThemeData.dark().textTheme, AppColors.pureWhite, AppColors.ivory),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.deepMaroon,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.antiqueGold, // Gold buttons on dark theme
          foregroundColor: AppColors.deepMaroon,
          elevation: 0,
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.charcoal,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.charcoal,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.mutedGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.mutedGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.antiqueGold),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, Color primaryColor, Color secondaryColor) {
    // Hero / Display → Playfair Display 700
    final playfairBold = GoogleFonts.playfairDisplay(color: primaryColor, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.1);
    // Screen Titles  → Cormorant Garamond 700
    final cormorantBold = GoogleFonts.cormorantGaramond(color: primaryColor, fontWeight: FontWeight.w700, letterSpacing: 0.3);
    // Sections       → Playfair Display 600
    final playfairSemi = GoogleFonts.playfairDisplay(color: primaryColor, fontWeight: FontWeight.w600);
    // Cards/Buttons  → Poppins 600
    final poppinsSemi = GoogleFonts.poppins(color: primaryColor, fontWeight: FontWeight.w600);
    // Body/Labels    → Inter 400/500
    final interRegular = GoogleFonts.inter(color: secondaryColor, fontWeight: FontWeight.w400, height: 1.5);
    final interMedium = GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.w500, height: 1.5);

    return base.copyWith(
      // displayLarge / displayMedium → Hero headings (Playfair Display 700)
      displayLarge:  playfairBold.copyWith(fontSize: 40),
      displayMedium: playfairBold.copyWith(fontSize: 32),
      displaySmall:  playfairBold.copyWith(fontSize: 26),

      // headlineLarge / headlineMedium → Screen titles (Cormorant Garamond 700)
      headlineLarge:  cormorantBold.copyWith(fontSize: 30),
      headlineMedium: cormorantBold.copyWith(fontSize: 26),
      headlineSmall:  cormorantBold.copyWith(fontSize: 22),

      // titleLarge → Section headings (Playfair Display 600)
      titleLarge:  playfairSemi.copyWith(fontSize: 20),
      // titleMedium → Card titles (Poppins 600)
      titleMedium: poppinsSemi.copyWith(fontSize: 16),
      // titleSmall → Chips/Labels (Poppins 500)
      titleSmall:  GoogleFonts.poppins(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w500),

      // bodyLarge  → Body text (Inter 500)
      bodyLarge:   interMedium.copyWith(fontSize: 15),
      // bodyMedium → Body / metadata (Inter 400)
      bodyMedium:  interRegular.copyWith(fontSize: 13),
      // bodySmall  → Location/Metadata (Inter 400)
      bodySmall:   interRegular.copyWith(fontSize: 11),

      // labelLarge  → Buttons (Poppins 600)
      labelLarge:  poppinsSemi.copyWith(fontSize: 15),
      // labelMedium → Navigation labels (Inter 500)
      labelMedium: GoogleFonts.inter(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w500),
      // labelSmall  → Stat numbers / ratings (Poppins 600)
      labelSmall:  GoogleFonts.poppins(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w600),
    );
  }
}
