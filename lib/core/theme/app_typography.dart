import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Central Typography System for PUJA24
class AppTypography {
  AppTypography._();

  // Hero Heading: Playfair Display 700 (Durga Puja Kolkata 2026)
  static TextStyle heroHeading({Color color = AppColors.deepMaroon, double fontSize = 36}) =>
      GoogleFonts.playfairDisplay(color: color, fontSize: fontSize, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.1);

  // Screen Title: Cormorant Garamond 700 (Explore Puja)
  static TextStyle screenTitle({Color color = AppColors.deepMaroon, double fontSize = 24}) =>
      GoogleFonts.cormorantGaramond(color: color, fontSize: fontSize, fontWeight: FontWeight.w700, letterSpacing: 0.2);

  // Section Heading: Playfair Display 600 (Popular Pujas)
  static TextStyle sectionHeading({Color color = AppColors.deepMaroon, double fontSize = 20}) =>
      GoogleFonts.playfairDisplay(color: color, fontSize: fontSize, fontWeight: FontWeight.w600);

  // Card Title: Poppins 600 (Ekdalia Evergreen)
  static TextStyle cardTitle({Color color = AppColors.deepMaroon, double fontSize = 15}) =>
      GoogleFonts.poppins(color: color, fontSize: fontSize, fontWeight: FontWeight.w600);

  // Body Text: Inter 400 (Discover the best pujas)
  static TextStyle bodyText({Color color = AppColors.charcoal, double fontSize = 14}) =>
      GoogleFonts.inter(color: color, fontSize: fontSize, fontWeight: FontWeight.w400, height: 1.5);

  // Body Medium: Inter 500
  static TextStyle bodyTextMedium({Color color = AppColors.charcoal, double fontSize = 14}) =>
      GoogleFonts.inter(color: color, fontSize: fontSize, fontWeight: FontWeight.w500, height: 1.5);

  // Button: Poppins 600 (View Details)
  static TextStyle button({Color color = const Color(0xFFFFFFFF), double fontSize = 14}) =>
      GoogleFonts.poppins(color: color, fontSize: fontSize, fontWeight: FontWeight.w600, letterSpacing: 0.3);

  // Chip/Label: Poppins 500 (Popular)
  static TextStyle chip({Color color = AppColors.deepMaroon, double fontSize = 13}) =>
      GoogleFonts.poppins(color: color, fontSize: fontSize, fontWeight: FontWeight.w500);

  // Stat Number: Poppins 700 (243+)
  static TextStyle statNumber({Color color = const Color(0xFFFFFFFF), double fontSize = 18}) =>
      GoogleFonts.poppins(color: color, fontSize: fontSize, fontWeight: FontWeight.w700);

  // Navigation Label: Inter 500 (Home · Puja · Plan)
  static TextStyle navLabel({Color color = AppColors.charcoal, double fontSize = 12}) =>
      GoogleFonts.inter(color: color, fontSize: fontSize, fontWeight: FontWeight.w500);

  // Location/Metadata: Inter 400 (Ballygunge, Kolkata)
  static TextStyle locationMeta({Color color = AppColors.mutedGray, double fontSize = 12}) =>
      GoogleFonts.inter(color: color, fontSize: fontSize, fontWeight: FontWeight.w400);

  // Rating: Poppins 600 (4.8)
  static TextStyle rating({Color color = AppColors.saffron, double fontSize = 12}) =>
      GoogleFonts.poppins(color: color, fontSize: fontSize, fontWeight: FontWeight.w600);

  // Subtitle: Inter 400
  static TextStyle subtitle({Color color = AppColors.mutedGray, double fontSize = 13}) =>
      GoogleFonts.inter(color: color, fontSize: fontSize, fontWeight: FontWeight.w400);
}
