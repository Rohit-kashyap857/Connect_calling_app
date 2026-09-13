import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    double letterSpacing = 0,
    Color color = AppColors.onSurface,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height / fontSize,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle headlineXl({Color? color}) => _base(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32,
        letterSpacing: -0.24,
        color: color ?? AppColors.onSurface,
      );

  static TextStyle headlineLg({Color? color}) => _base(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 28,
        letterSpacing: -0.20,
        color: color ?? AppColors.onSurface,
      );

  static TextStyle headlineMd({Color? color}) => _base(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 24,
        color: color ?? AppColors.onSurface,
      );

  static TextStyle bodyMd({Color? color}) => _base(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 20,
        color: color ?? AppColors.onSurfaceVariant,
      );

  static TextStyle bodySm({Color? color}) => _base(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16,
        color: color ?? AppColors.onSurfaceVariant,
      );

  static TextStyle labelUppercase({Color? color}) => _base(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 12,
        letterSpacing: 0.5,
        color: color ?? AppColors.primary,
      );

  static TextStyle labelSm({Color? color}) => _base(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 12,
        color: color ?? AppColors.onSurfaceVariant,
      );
}
