import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color primary = Color(0xFFFFB2BF);
  static const Color primaryPulse = Color(0xFFEE2B6C); // high-fidelity "Pulse Pink"
  static const Color onPrimary = Color(0xFF660027);
  static const Color primaryContainer = Color(0xFFFF4D7F);
  static const Color onPrimaryContainer = Color(0xFF5A0021);
  static const Color inversePrimary = Color(0xFFBC004E);

  static const Color secondary = Color(0xFFC6C6C7);
  static const Color onSecondary = Color(0xFF2F3131);
  static const Color secondaryContainer = Color(0xFF454747);
  static const Color onSecondaryContainer = Color(0xFFB4B5B5);

  static const Color tertiary = Color(0xFF68DE82);
  static const Color onTertiary = Color(0xFF003915);
  static const Color tertiaryContainer = Color(0xFF29A552);
  static const Color onTertiaryContainer = Color(0xFF003111);

  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  static const Color surface = Color(0xFF1E0F12);
  static const Color surfaceDim = Color(0xFF1E0F12);
  static const Color surfaceBright = Color(0xFF473437);
  static const Color surfaceContainerLowest = Color(0xFF180A0D);
  static const Color surfaceContainerLow = Color(0xFF27171A);
  static const Color surfaceContainer = Color(0xFF2C1B1E);
  static const Color surfaceContainerHigh = Color(0xFF372528);
  static const Color surfaceContainerHighest = Color(0xFF433033);
  static const Color surfaceVariant = Color(0xFF433033);

  static const Color onSurface = Color(0xFFF9DBDF);
  static const Color onSurfaceVariant = Color(0xFFE3BDC2);
  static const Color inverseSurface = Color(0xFFF9DBDF);
  static const Color inverseOnSurface = Color(0xFF3E2C2E);

  static const Color outline = Color(0xFFAA888D);
  static const Color outlineVariant = Color(0xFF5B3F44);

  static const Color background = Color(0xFF1E0F12);
  static const Color backgroundDark = Color(0xFF16080C);
  static const Color onBackground = Color(0xFFF9DBDF);
  static const Color backgroundLight = Color(0xFFF8F6F6);

  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color verifiedBlue = Color(0xFF60A5FA);
  static Color glassWhite5 = Colors.white.withValues(alpha: 0.05);
  static Color glassWhite10 = Colors.white.withValues(alpha: 0.10);
  static Color glassBorder = Colors.white.withValues(alpha: 0.10);
  static Color primaryGlow = primaryPulse.withValues(alpha: 0.25);
  static Color primaryTonal5 = primaryPulse.withValues(alpha: 0.05);
  static Color primaryTonal20 = primaryPulse.withValues(alpha: 0.20);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPulse, primaryContainer],
  );
}
