import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_color_extension.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/gradient_button.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  bool _obscurePassword = true;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);

    await controller.signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    final state = ref.read(authControllerProvider);

    if (state.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error.toString()),
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
                          'Create Account',
                          style: AppTextStyles.headlineMd(
                            color: context.colors.onSurface,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Create your account to get started',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySm(
                            color: context.colors.slate500,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // FULL NAME
                        _label('Full Name'),

                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          style: AppTextStyles.bodyMd(
                            color: context.colors.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Rohit Kashyap',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: context.colors.slate500,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter your name';
                            }

                            if (v.trim().length < 2) {
                              return 'Enter a valid name';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // PHONE NUMBER
                        _label('Phone Number'),

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
                          validator: (v) {
                            final phone = v?.trim() ?? '';

                            if (phone.isEmpty) {
                              return 'Enter your phone number';
                            }

                            final digits =
                            phone.replaceAll(RegExp(r'\D'), '');

                            if (digits.length != 10 &&
                                digits.length != 12) {
                              return 'Enter a valid phone number';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // EMAIL
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

                        // PASSWORD
                        _label('Password'),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autofillHints: const [
                            AutofillHints.newPassword,
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

                        // CREATE ACCOUNT
                        GradientButton(
                          label: 'Create My Account',
                          icon: Icons.arrow_forward_rounded,
                          isLoading: authState.isLoading,
                          onPressed: _submit,
                        ),

                        const SizedBox(height: 24),

                        // DIVIDER
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: context.colors.glassBorder,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'Or continue with',
                                style: AppTextStyles.labelUppercase(
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

                        // GOOGLE LOGIN
                        Center(
                          child: InkWell(
                            onTap: authState.isLoading
                                ? null
                                : () async {
                              await ref
                                  .read(
                                authControllerProvider
                                    .notifier,
                              )
                                  .signInWithGoogle();
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.08,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                      BorderRadius.circular(8),
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

                        // LOGIN
                        TextButton(
                          onPressed: () {
                            context.go('/login');
                          },
                          child: Text(
                            'Already have an account? Login',
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
}