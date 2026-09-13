import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppSurfaceColors extends ThemeExtension<AppSurfaceColors> {
  const AppSurfaceColors({
    required this.background,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.glassBorder,
    required this.glassWhite5,
    required this.glassWhite10,
  });

  final Color background;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color glassBorder;
  final Color glassWhite5;
  final Color glassWhite10;

  static const AppSurfaceColors dark = AppSurfaceColors(
    background: AppColors.backgroundDark,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    glassBorder: Color(0x1AFFFFFF), // Colors.white @ 10% alpha
    glassWhite5: Color(0x0DFFFFFF), // Colors.white @ 5% alpha
    glassWhite10: Color(0x1AFFFFFF), // Colors.white @ 10% alpha
  );

  static const AppSurfaceColors light = AppSurfaceColors(
    background: AppColors.backgroundLight,
    onSurface: Color(0xFF241417),
    onSurfaceVariant: Color(0xFF5C4247),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFF8F8F8),
    surfaceContainer: Color(0xFFF3F3F3),
    surfaceContainerHigh: Color(0xFFECECEC),
    surfaceContainerHighest: Color(0xFFE5E5E5),
    glassBorder: Color(0x14000000), // Colors.black @ 8% alpha
    glassWhite5: Color(0x08000000), // Colors.black @ 3% alpha
    glassWhite10: Color(0x14000000), // Colors.black @ 8% alpha
  );

  @override
  AppSurfaceColors copyWith({
    Color? background,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? surfaceContainerLowest,
    Color? surfaceContainerLow,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? glassBorder,
    Color? glassWhite5,
    Color? glassWhite10,
  }) {
    return AppSurfaceColors(
      background: background ?? this.background,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      surfaceContainerLowest:
          surfaceContainerLowest ?? this.surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainerHighest:
          surfaceContainerHighest ?? this.surfaceContainerHighest,
      glassBorder: glassBorder ?? this.glassBorder,
      glassWhite5: glassWhite5 ?? this.glassWhite5,
      glassWhite10: glassWhite10 ?? this.glassWhite10,
    );
  }

  @override
  AppSurfaceColors lerp(ThemeExtension<AppSurfaceColors>? other, double t) {
    if (other is! AppSurfaceColors) return this;
    return AppSurfaceColors(
      background: Color.lerp(background, other.background, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant: Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      surfaceContainerLowest:
          Color.lerp(surfaceContainerLowest, other.surfaceContainerLowest, t)!,
      surfaceContainerLow:
          Color.lerp(surfaceContainerLow, other.surfaceContainerLow, t)!,
      surfaceContainer: Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      surfaceContainerHigh:
          Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
      surfaceContainerHighest: Color.lerp(
          surfaceContainerHighest, other.surfaceContainerHighest, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassWhite5: Color.lerp(glassWhite5, other.glassWhite5, t)!,
      glassWhite10: Color.lerp(glassWhite10, other.glassWhite10, t)!,
    );
  }
}

class AppRadius {
  AppRadius._();

  static const double sm = 4;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double full = 999;
}

class AppSpacing {
  AppSpacing._();

  static const double containerMargin = 16;
  static const double stackGapSm = 12;
  static const double stackGapMd = 16;
  static const double stackGapLg = 24;
  static const double sectionPadding = 24;
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final Color background =
    isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    final Color surface =
    isDark ? AppColors.surface : Colors.white;

    final Color onSurface =
    isDark ? AppColors.onSurface : Colors.black87;

    final Color onSurfaceVariant =
    isDark ? AppColors.onSurfaceVariant : Colors.black54;

    final Color outline =
    isDark ? AppColors.outline : Colors.grey.shade400;

    final Color outlineVariant =
    isDark ? AppColors.outlineVariant : Colors.grey.shade300;

    final scheme = ColorScheme(
      brightness: brightness,

      primary: AppColors.primaryPulse,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,

      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,

      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,

      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,

      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,

      surfaceContainerLowest:
      isDark ? AppColors.surfaceContainerLowest : Colors.white,

      surfaceContainerLow:
      isDark ? AppColors.surfaceContainerLow : const Color(0xFFF8F8F8),

      surfaceContainer:
      isDark ? AppColors.surfaceContainer : const Color(0xFFF3F3F3),

      surfaceContainerHigh:
      isDark ? AppColors.surfaceContainerHigh : const Color(0xFFECECEC),

      surfaceContainerHighest:
      isDark ? AppColors.surfaceContainerHighest : const Color(0xFFE5E5E5),

      outline: outline,
      outlineVariant: outlineVariant,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      inversePrimary: AppColors.inversePrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,

      scaffoldBackgroundColor: background,

      fontFamily: 'PlusJakartaSans',

      textTheme: TextTheme(
        headlineLarge:
        AppTextStyles.headlineXl(color: onSurface),

        headlineMedium:
        AppTextStyles.headlineLg(color: onSurface),

        headlineSmall:
        AppTextStyles.headlineMd(color: onSurface),

        bodyMedium:
        AppTextStyles.bodyMd(color: onSurfaceVariant),

        bodySmall:
        AppTextStyles.bodySm(color: onSurfaceVariant),

        labelSmall:
        AppTextStyles.labelSm(color: onSurfaceVariant),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,

        titleTextStyle:
        AppTextStyles.headlineMd(color: AppColors.primaryPulse),

        iconTheme:
        IconThemeData(color: onSurface),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPulse,
          foregroundColor: Colors.white,

          minimumSize:
          const Size.fromHeight(56),

          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(AppRadius.full),
          ),

          textStyle:
          AppTextStyles.bodyMd(color: Colors.white)
              .copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryPulse,

          side: BorderSide(
            color: AppColors.glassBorder,
          ),

          minimumSize:
          const Size.fromHeight(56),

          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(AppRadius.full),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,

        fillColor:
        AppColors.glassWhite5,

        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(AppRadius.lg),

          borderSide:
          BorderSide(
            color: AppColors.glassBorder,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(AppRadius.lg),

          borderSide:
          BorderSide(
            color: AppColors.glassBorder,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(AppRadius.lg),

          borderSide:
          const BorderSide(
            color: AppColors.primaryPulse,
            width: 1.5,
          ),
        ),

        hintStyle:
        AppTextStyles.bodyMd(
          color: AppColors.slate500,
        ),
      ),

      navigationBarTheme:
      NavigationBarThemeData(
        backgroundColor:
        AppColors.surfaceContainerLowest
            .withValues(alpha: 0.92),

        indicatorColor:
        AppColors.primaryPulse
            .withValues(alpha: 0.20),

        surfaceTintColor:
        Colors.transparent,

        labelTextStyle:
        WidgetStateProperty.resolveWith(
              (states) {
            final selected =
            states.contains(
              WidgetState.selected,
            );

            return AppTextStyles.labelSm(
              color: selected
                  ? AppColors.primaryPulse
                  : AppColors.slate500,
            );
          },
        ),

        iconTheme:
        WidgetStateProperty.resolveWith(
              (states) {
            final selected =
            states.contains(
              WidgetState.selected,
            );

            return IconThemeData(
              color: selected
                  ? AppColors.primaryPulse
                  : AppColors.slate500,
            );
          },
        ),
      ),

      dividerTheme:
      DividerThemeData(
        color: isDark ? AppSurfaceColors.dark.glassBorder : AppSurfaceColors.light.glassBorder,
        thickness: 1,
      ),

      extensions: <ThemeExtension<dynamic>>[
        isDark ? AppSurfaceColors.dark : AppSurfaceColors.light,
      ],
    );
  }
}