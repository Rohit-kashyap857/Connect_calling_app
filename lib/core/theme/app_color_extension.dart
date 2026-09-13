import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_theme.dart';

extension AppColorsExtension on BuildContext {
  AppColorsTheme get colors => AppColorsTheme(this);
}

class AppColorsTheme {
  AppColorsTheme(this._context);

  final BuildContext _context;

  AppSurfaceColors get _surface =>
      Theme.of(_context).extension<AppSurfaceColors>() ?? AppSurfaceColors.dark;

  // ---- Brand constants: same in light & dark ----
  Color get primary => AppColors.primary;
  Color get primaryPulse => AppColors.primaryPulse;

  Color get onPrimary => AppColors.onPrimary;

  Color get primaryContainer =>
      AppColors.primaryContainer;

  Color get onPrimaryContainer =>
      AppColors.onPrimaryContainer;

  Color get secondary =>
      AppColors.secondary;

  Color get onSecondary =>
      AppColors.onSecondary;

  Color get secondaryContainer =>
      AppColors.secondaryContainer;

  Color get onSecondaryContainer =>
      AppColors.onSecondaryContainer;

  Color get tertiary =>
      AppColors.tertiary;

  Color get onTertiary =>
      AppColors.onTertiary;

  Color get tertiaryContainer =>
      AppColors.tertiaryContainer;

  Color get onTertiaryContainer =>
      AppColors.onTertiaryContainer;

  Color get error =>
      AppColors.error;

  Color get onError =>
      AppColors.onError;

  Color get errorContainer =>
      AppColors.errorContainer;

  Color get slate400 =>
      AppColors.slate400;

  Color get slate500 =>
      AppColors.slate500;

  Color get verifiedBlue =>
      AppColors.verifiedBlue;

  Color get primaryGlow =>
      AppColors.primaryGlow;

  Color get primaryTonal5 =>
      AppColors.primaryTonal5;

  Color get primaryTonal20 =>
      AppColors.primaryTonal20;

  LinearGradient get primaryGradient => AppColors.primaryGradient;
  Color get background => _surface.background;
  Color get backgroundDeepest => _surface.background;

  Color get onSurface => _surface.onSurface;

  Color get onSurfaceVariant => _surface.onSurfaceVariant;

  Color get surface => _surface.surfaceContainerLowest;

  Color get surfaceContainerLowest => _surface.surfaceContainerLowest;

  Color get surfaceContainerLow => _surface.surfaceContainerLow;

  Color get surfaceContainer => _surface.surfaceContainer;

  Color get surfaceContainerHigh => _surface.surfaceContainerHigh;

  Color get surfaceContainerHighest => _surface.surfaceContainerHighest;

  Color get outline => Theme.of(_context).colorScheme.outline;

  Color get outlineVariant => Theme.of(_context).colorScheme.outlineVariant;

  Color get glassSurface5 => _surface.glassWhite5;

  Color get glassSurface10 => _surface.glassWhite10;

  Color get glassBorder => _surface.glassBorder;
}
