import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_color_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: profile.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
          error: (error, _) => _ErrorView(
            error: '$error',
          ),
          data: (user) => _ProfileContent(
            user: user,
            onLogout: () {
              ref
                  .read(authControllerProvider.notifier)
                  .signOut();
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerStatefulWidget {
  const _ProfileContent({
    required this.user,
    required this.onLogout,
  });

  final UserModel? user;
  final VoidCallback onLogout;

  @override
  ConsumerState<_ProfileContent> createState() =>
      _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<_ProfileContent> {
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  bool _isPickingImage = false;

  // ------------------------------------------------------------
  // PROFILE PHOTO
  // ------------------------------------------------------------

  Future<void> _showImagePicker() async {
    if (_isPickingImage) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: sheetContext.colors.onSurfaceVariant.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Update Profile Photo',
                  style: TextStyle(
                    color: sheetContext.colors.onSurface,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose how you want to add your photo',
                  style: TextStyle(
                    color: sheetContext.colors.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _ImageSourceButton(
                        icon: Icons.photo_library_rounded,
                        title: 'Gallery',
                        subtitle: 'Choose photo',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ImageSourceButton(
                        icon: Icons.camera_alt_rounded,
                        title: 'Camera',
                        subtitle: 'Take photo',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) return;

      if (!mounted) return;

      setState(() {
        _selectedImage = image;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile photo selected. Upload will be added next.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to select image: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _showPhoneNumberDialog() async {
    final existingPhone = widget.user?.phoneNumber?.trim() ?? '';

    // Phone number already exists → it cannot be changed.
    if (existingPhone.isNotEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Phone number cannot be changed once added.',
          ),
        ),
      );

      return;
    }

    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (_, setDialogState) {
            Future<void> save() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              final uid = widget.user?.uid;

              if (uid == null || uid.isEmpty) {
                return;
              }

              setDialogState(() {
                saving = true;
              });

              try {
                final phone = controller.text.trim();

                await ref
                    .read(userRepositoryProvider)
                    .updateProfile(
                  uid,
                  {
                    'phoneNumber': phone,
                  },
                );

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(true);
                }
              } catch (e) {
                if (!dialogContext.mounted) return;

                setDialogState(() {
                  saving = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Unable to add phone number: $e',
                    ),
                  ),
                );
              }
            }

            return AlertDialog(
              backgroundColor: dialogContext.colors.surfaceContainerHigh,
              title: Text(
                'Add Phone Number',
                style: TextStyle(
                  color: dialogContext.colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '+91 9876543210',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                    ),
                  ),
                  validator: (value) {
                    final phone = value?.trim() ?? '';

                    if (phone.isEmpty) {
                      return 'Enter your phone number';
                    }

                    final digits = phone.replaceAll(
                      RegExp(r'\D'),
                      '',
                    );

                    if (digits.length != 10 &&
                        digits.length != 12) {
                      return 'Enter a valid phone number';
                    }

                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving ? null : save,
                  child: saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Phone number added successfully. It cannot be changed later.',
          ),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // BUILD PROFILE
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final name = widget.user?.fullName.isNotEmpty == true
        ? widget.user!.fullName
        : 'User';

    final email = widget.user?.email ?? '';

    final phone = widget.user?.phoneNumber?.trim() ?? '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        30,
      ),
      child: Column(
        children: [
          // HEADER
          Row(
            children: [
              Expanded(
                child: Text(
                  'My Profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.colors.onSurface,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 46),
            ],
          ),

          const SizedBox(height: 30),

          // PROFILE CARD
          _ProfileCard(
            user: widget.user,
            selectedImage: _selectedImage,
            name: name,
            email: email,
            phone: phone,
            isPickingImage: _isPickingImage,
            onImageTap: _showImagePicker,
          ),

          const SizedBox(height: 24),

          // ACCOUNT
          const _SectionTitle(
            title: 'ACCOUNT',
          ),

          const SizedBox(height: 10),

          _ProfileOption(
            icon: Icons.person_outline_rounded,
            title: 'Personal Information',
            subtitle: 'Manage your name and profile',
            onTap: () {},
          ),

          const SizedBox(height: 10),

          _ProfileOption(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: email.isEmpty
                ? 'No email available'
                : email,
            onTap: () {},
          ),

          const SizedBox(height: 10),

          _ProfileOption(
            icon: Icons.phone_outlined,
            title: 'Phone Number',
            subtitle: phone.isEmpty
                ? 'Add your phone number'
                : phone,
            onTap: _showPhoneNumberDialog,
          ),

          const SizedBox(height: 24),

          // APP SETTINGS
          const _SectionTitle(
            title: 'APP SETTINGS',
          ),

          const SizedBox(height: 10),

          _NotificationOption(
            onChanged: (enabled) {
              // Setting is saved inside _NotificationOption.
            },
          ),

          const SizedBox(height: 10),

          const _ThemeOption(),

          const SizedBox(height: 10),

          _ProfileOption(
            icon: Icons.security_outlined,
            title: 'Privacy & Security',
            subtitle: 'Control your privacy settings',
            onTap: () {},
          ),

          const SizedBox(height: 10),

          _ProfileOption(
            icon: Icons.info_outline_rounded,
            title: 'About ConnectCall',
            subtitle: 'Version 1.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'ConnectCall',
                applicationVersion: '1.0.0',
                applicationLegalese:
                'Connect with anyone, anywhere.',
              );
            },
          ),

          const SizedBox(height: 28),

          // LOGOUT
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: widget.onLogout,
              style: FilledButton.styleFrom(
                backgroundColor:
                AppColors.errorContainer.withValues(
                  alpha: 0.85,
                ),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(
                Icons.logout_rounded,
              ),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'ConnectCall • Connect with anyone, anywhere.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.onSurfaceVariant.withValues(
                alpha: 0.55,
              ),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PROFILE CARD
// ============================================================

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.selectedImage,
    required this.name,
    required this.email,
    required this.phone,
    required this.isPickingImage,
    required this.onImageTap,
  });

  final UserModel? user;
  final XFile? selectedImage;
  final String name;
  final String email;
  final String phone;
  final bool isPickingImage;
  final VoidCallback onImageTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        22,
        28,
        22,
        24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.surfaceContainerHigh,
            context.colors.surfaceContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: context.colors.glassBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPulse.withValues(
              alpha: 0.10,
            ),
            blurRadius: 30,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // PROFILE AVATAR
          GestureDetector(
            onTap: onImageTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.surfaceContainerHigh,
                    ),
                    child: ClipOval(
                      child: selectedImage != null
                          ? Image.file(
                        File(selectedImage!.path),
                        fit: BoxFit.cover,
                      )
                          : user?.photoUrl.isNotEmpty == true
                          ? Image.network(
                        user!.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (
                            _,
                            __,
                            ___,
                            ) {
                          return _InitialAvatar(
                            name: name,
                          );
                        },
                      )
                          : _InitialAvatar(
                        name: name,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  right: -2,
                  bottom: 2,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      border: Border.all(
                        color:
                        context.colors.surfaceContainerHigh,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(
                            alpha: 0.35,
                          ),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: isPickingImage
                        ? const Padding(
                      padding: EdgeInsets.all(9),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons.camera_alt_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 17),

          // NAME
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          // EMAIL
          if (email.isNotEmpty)
            Text(
              email,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                context.colors.onSurfaceVariant.withValues(
                  alpha: 0.75,
                ),
                fontSize: 13,
              ),
            ),

          // PHONE
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              phone,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                context.colors.onSurfaceVariant.withValues(
                  alpha: 0.75,
                ),
                fontSize: 13,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // ACTIVE MEMBER
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.tertiary.withValues(
                  alpha: 0.20,
                ),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: AppColors.tertiary,
                ),
                SizedBox(width: 7),
                Text(
                  'Active ConnectCall member',
                  style: TextStyle(
                    color: AppColors.tertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// IMAGE SOURCE BUTTON
// ============================================================

class _ImageSourceButton extends StatelessWidget {
  const _ImageSourceButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainer,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 10,
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  color: context.colors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color:
                  context.colors.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// INITIAL AVATAR
// ============================================================

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({
    required this.name,
  });

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial =
    name.isEmpty ? '?' : name[0].toUpperCase();

    return Container(
      color: context.colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 42,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================
// PROFILE OPTION
// ============================================================

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainer.withValues(
        alpha: 0.80,
      ),
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: context.colors.glassBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryPulse.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.colors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                        context.colors.onSurfaceVariant
                            .withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: context.colors.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color:
          context.colors.onSurfaceVariant.withValues(
            alpha: 0.65,
          ),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ============================================================
// ERROR VIEW
// ============================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.error,
  });

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.error,
              size: 44,
            ),
            const SizedBox(height: 14),
            Text(
              'Unable to load profile',
              style: TextStyle(
                color: context.colors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                context.colors.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// NOTIFICATION OPTION
// ============================================================

class _NotificationOption extends ConsumerStatefulWidget {
  const _NotificationOption({
    required this.onChanged,
  });

  final ValueChanged<bool> onChanged;

  @override
  ConsumerState<_NotificationOption> createState() =>
      _NotificationOptionState();
}

class _NotificationOptionState
    extends ConsumerState<_NotificationOption> {
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final enabled = await ref
        .read(notificationServiceProvider)
        .areNotificationsEnabled();

    if (!mounted) return;

    setState(() {
      _enabled = enabled;
    });
  }

  Future<void> _changeNotificationSetting(
      bool value,
      ) async {
    setState(() {
      _enabled = value;
    });

    try {
      await ref
          .read(notificationServiceProvider)
          .setNotificationsEnabled(value);

      widget.onChanged(value);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _enabled = !value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update notification setting: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainer.withValues(
        alpha: 0.80,
      ),
      borderRadius: BorderRadius.circular(19),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: context.colors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primaryPulse.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _enabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      color: context.colors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage call notifications',
                    style: TextStyle(
                      color: context.colors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            Switch(
              value: _enabled,
              onChanged: _changeNotificationSetting,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// THEME OPTION
// ============================================================

/// Toggle for switching the whole app between light and dark mode.
/// ON = Dark Theme, OFF = Light Theme. Persisted via [themeModeProvider].
class _ThemeOption extends ConsumerWidget {
  const _ThemeOption();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Material(
      color: context.colors.surfaceContainer.withValues(
        alpha: 0.80,
      ),
      borderRadius: BorderRadius.circular(19),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: context.colors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primaryPulse.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: TextStyle(
                      color: context.colors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDark ? 'Dark theme' : 'Light theme',
                    style: TextStyle(
                      color: context.colors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            Switch(
              value: isDark,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}