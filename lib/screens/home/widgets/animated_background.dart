import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Three softly blurred, slowly drifting orbs used as the home
/// screen's ambient background. Driven by an external [controller]
/// so the parent owns the animation lifecycle.
class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({
    super.key,
    required this.controller,
  });

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = controller.value;

        return Stack(
          children: [
            Positioned(
              top: -120 + (value * 45),
              right: -100,
              child: GlowOrb(
                size: 280,
                color: AppColors.primaryPulse,
              ),
            ),
            Positioned(
              top: 260 - (value * 60),
              left: -150,
              child: GlowOrb(
                size: 300,
                color: const Color(0xFF7C3AED),
              ),
            ),
            Positioned(
              bottom: -160 + (value * 50),
              right: -120,
              child: GlowOrb(
                size: 280,
                color: const Color(0xFF2563EB),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A single soft, blurred, semi-transparent circle used by
/// [AnimatedBackground].
class GlowOrb extends StatelessWidget {
  const GlowOrb({
    super.key,
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: 80,
          sigmaY: 80,
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.14),
          ),
        ),
      ),
    );
  }
}