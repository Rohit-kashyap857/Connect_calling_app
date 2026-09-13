import 'package:flutter/material.dart';

import '../../../core/theme/app_color_extension.dart';

/// Glass-styled circular icon button, used in the app bar (e.g. search).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.glassSurface10,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            color: context.colors.onSurface,
          ),
        ),
      ),
    );
  }
}