import 'package:flutter/material.dart';

import '../../../core/theme/app_color_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user_model.dart';

/// Circular avatar for a [UserModel] with an online-status dot and
/// a gradient-initial fallback when there is no photo (or it fails to load).
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.user,
  });

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final name =
    user.fullName.isEmpty ? 'U' : user.fullName[0].toUpperCase();

    return Stack(
      children: [
        Container(
          width: 55,
          height: 55,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: user.photoUrl.isNotEmpty
                ? Image.network(
              user.photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _avatarInitial(context, name),
            )
                : _avatarInitial(context, name),
          ),
        ),
        if (user.isOnline)
          Positioned(
            right: 0,
            bottom: 1,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tertiary,
                border: Border.all(
                  color: context.colors.surfaceContainer,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _avatarInitial(BuildContext context, String initial) {
    return Container(
      color: context.colors.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}