import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'appColor.dart';

class AppTypography {
  // Primary font family for the app
  static String get fontFamily => 'Inter';
  
  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // Text styles for different use cases
  
  // Headers and titles
  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle get displayMedium => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: semiBold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: semiBold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get headlineSmall => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: semiBold,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Section headers (for ADA YAKO, HISA ZAKO, etc.)
  static TextStyle get sectionHeader => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: semiBold,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // Body text
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: regular,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: regular,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: regular,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Labels and captions
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: medium,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: medium,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Special use cases
  
  // For financial amounts and numbers
  static TextStyle get currency => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: semiBold,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static TextStyle get currencyLarge => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: bold,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: 0.5,
  );

  // For buttons
  static TextStyle get buttonLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: medium,
    height: 1.2,
  );

  static TextStyle get buttonMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    height: 1.2,
  );

  static TextStyle get buttonSmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: medium,
    height: 1.2,
  );

  // For inputs and form fields
  static TextStyle get input => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: regular,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get inputLabel => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: medium,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // For navigation and tabs
  static TextStyle get navigation => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: medium,
    height: 1.2,
  );

  // Chat message styles
  static TextStyle get chatMessage => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: regular,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle get chatTimestamp => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: regular,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  // Helper method to create custom styles with Inter font
  static TextStyle custom({
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight ?? regular,
      color: color ?? AppColors.textPrimary,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // Theme data for the entire app
  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}