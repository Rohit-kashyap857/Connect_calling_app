import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_color_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/core_providers.dart';
import '../../widgets/gradient_button.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState
    extends ConsumerState<CompleteProfileScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _savePhoneNumber() async {
    if (!_formKey.currentState!.validate()) return;

    final firebaseUser =
        ref.read(authServiceProvider).currentUser;

    if (firebaseUser == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final phone = _phoneController.text.trim();

      await ref.read(userRepositoryProvider).updateProfile(
        firebaseUser.uid,
        {
          'phoneNumber': phone,
        },
      );

      if (!mounted) return;

      context.go('/');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save phone number: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser =
        ref.read(authServiceProvider).currentUser;

    final name = firebaseUser?.displayName ?? 'User';

    return Scaffold(
      backgroundColor: context.colors.backgroundDeepest,
      body: Stack(
        children: [
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.primaryPulse.withValues(
                    alpha: 0.18,
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainer
                        .withValues(alpha: 0.85),
                    borderRadius:
                    BorderRadius.circular(AppRadius.xxl),
                    border: Border.all(
                      color: context.colors.glassBorder,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient:
                            AppColors.primaryGradient,
                          ),
                          child: const Icon(
                            Icons.phone_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),

                        const SizedBox(height: 24),

                        Text(
                          'Complete Your Profile',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headlineMd(
                            color: context.colors.onSurface,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'Hi $name! Add your phone number so other ConnectCall users can find and call you.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySm(
                            color: context.colors.slate500,
                          ),
                        ),

                        const SizedBox(height: 28),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'PHONE NUMBER',
                            style:
                            AppTextStyles.labelUppercase(
                              color:
                              context.colors.onSurfaceVariant,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          autofillHints: const [
                            AutofillHints.telephoneNumber,
                          ],
                          style: AppTextStyles.bodyMd(
                            color: context.colors.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: '+91 9876543210',
                            prefixIcon: Icon(
                              Icons.phone_outlined,
                              color: context.colors.slate500,
                            ),
                          ),
                          validator: (value) {
                            final phone =
                                value?.trim() ?? '';

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

                        const SizedBox(height: 24),

                        GradientButton(
                          label: 'Save & Continue',
                          icon: Icons.arrow_forward_rounded,
                          isLoading: _isSaving,
                          onPressed: _savePhoneNumber,
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Your phone number will be used to help other users find you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.colors.slate500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}