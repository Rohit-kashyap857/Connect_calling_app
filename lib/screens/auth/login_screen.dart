import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_color_extension.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/gradient_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);

    await controller.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );

    final state = ref.read(authControllerProvider);

    if (state.hasError && mounted) {
      String message = 'Login failed. Please try again.';

      final error = state.error.toString().toLowerCase();

      if (error.contains('user-not-found') ||
          error.contains('user-not-found')) {
        message = 'Account is not created. Please sign up first.';
      } else if (error.contains('wrong-password') ||
          error.contains('invalid-credential')) {
        message = 'Incorrect email or password.';
      } else if (error.contains('invalid-email')) {
        message = 'Please enter a valid email address.';
      } else if (error.contains('too-many-requests')) {
        message = 'Too many attempts. Please try again later.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);


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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainer.withValues(
                      alpha: 0.85,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    border: Border.all(
                      color: context.colors.glassBorder,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Welcome Back',
                          style: AppTextStyles.headlineMd(
                            color: context.colors.onSurface,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Login to continue',
                          style: AppTextStyles.bodySm(
                            color: context.colors.slate500,
                          ),
                        ),

                        const SizedBox(height: 28),

                        _label('Email Address'),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [
                            AutofillHints.email,
                          ],
                          style: AppTextStyles.bodyMd(
                            color: context.colors.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'hello@example.com',
                            prefixIcon: Icon(
                              Icons.mail_outline_rounded,
                              color: context.colors.slate500,
                            ),
                          ),
                          validator: (v) {
                            final email = v?.trim() ?? '';

                            if (email.isEmpty) {
                              return 'Enter your email';
                            }

                            if (!email.contains('@') ||
                                !email.contains('.')) {
                              return 'Enter a valid email';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            _label('Password'),
                            TextButton(
                              onPressed: () async {
                                final email =
                                _emailController.text.trim();

                                if (email.isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content:
                                      Text('Enter your email first'),
                                    ),
                                  );
                                  return;
                                }

                                await ref
                                    .read(
                                  authControllerProvider.notifier,
                                )
                                    .sendPasswordReset(email);

                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Password reset email sent',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                'Forgot Password?',
                                style: AppTextStyles.bodySm(
                                  color: context.colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autofillHints: const [
                            AutofillHints.password,
                          ],
                          style: AppTextStyles.bodyMd(
                            color: context.colors.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              color: context.colors.slate500,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: context.colors.slate500,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword =
                                  !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Enter your password';
                            }

                            if (v.length < 6) {
                              return 'Min 6 characters';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        GradientButton(
                          label: 'Login to My Account',
                          icon: Icons.arrow_forward_rounded,
                          isLoading: authState.isLoading,
                          onPressed: _submit,
                        ),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: context.colors.glassBorder,
                              ),
                            ),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'Or continue with',
                                style:
                                AppTextStyles.labelUppercase(
                                  color: context.colors.slate500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: context.colors.glassBorder,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Center(
                          child: InkWell(
                            onTap: authState.isLoading
                                ? null
                                : () async {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .signInWithGoogle();
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'G',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF4285F4),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Continue with Google',
                                    style: AppTextStyles.bodyMd(
                                      color: Colors.black87,
                                    ).copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        TextButton(
                          onPressed: () {
                            context.go('/signup');
                          },
                          child: Text(
                            'Create a new account',
                            style: AppTextStyles.bodySm(
                              color: context.colors.primary,
                            ),
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

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
        top: 4,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: AppTextStyles.labelUppercase(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _socialButton(
      IconData icon,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        AppRadius.full,
      ),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.colors.glassSurface10,
          border: Border.all(
            color: context.colors.glassBorder,
          ),
        ),
        child: Icon(
          icon,
          color: context.colors.onSurface,
        ),
      ),
    );
  }
}