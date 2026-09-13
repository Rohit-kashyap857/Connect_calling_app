import 'package:connect_call_assignment/screens/home/contacts_tab.dart';
import 'package:connect_call_assignment/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_color_extension.dart';
import '../../core/theme/app_colors.dart';
import 'call_history_tab.dart';
import 'widgets/animated_background.dart';
import 'widgets/glass_icon_button.dart';

class AssignmentHomeScreen extends ConsumerStatefulWidget {
  const AssignmentHomeScreen({super.key});

  @override
  ConsumerState<AssignmentHomeScreen> createState() =>
      _AssignmentHomeScreenState();
}

class _AssignmentHomeScreenState extends ConsumerState<AssignmentHomeScreen>
    with SingleTickerProviderStateMixin {
  int index = 0;

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String get _title {
    switch (index) {
      case 0:
        return 'Contacts';
      case 1:
        return 'Call History';
      case 2:
        return 'Profile';
      default:
        return 'ConnectCall';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          AnimatedBackground(
            controller: _animationController,
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),

                Expanded(
                  child: IndexedStack(
                    index: index,
                    children: const [
                      ContactsTab(),
                      CallHistoryTab(),
                      ProfileScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        14,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPulse.withValues(
                    alpha: 0.25,
                  ),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.asset(
                'assets/images/app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(
                        bounds,
                      ),
                  child: const Text(
                    'ConnectCall',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                Text(
                  _title,
                  style: TextStyle(
                    color: context.colors.onSurfaceVariant.withValues(
                      alpha: 0.75,
                    ),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          if (index != 2)
            GlassIconButton(
              icon: Icons.search_rounded,
              onTap: () {
                context.push('/search');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest.withValues(
          alpha: 0.96,
        ),
        border: Border(
          top: BorderSide(
            color: context.colors.glassBorder,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          height: 72,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedIndex: index,

          onDestinationSelected: (value) {
            if (value == index) {
              return;
            }

            setState(() {
              index = value;
            });
          },

          indicatorColor: AppColors.primaryPulse.withValues(
            alpha: 0.16,
          ),

          labelTextStyle: WidgetStateProperty.resolveWith(
                (states) {
              final selected = states.contains(
                WidgetState.selected,
              );

              return TextStyle(
                color: selected
                    ? AppColors.primary
                    : context.colors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
              );
            },
          ),

          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.people_outline_rounded,
                color: context.colors.onSurfaceVariant,
              ),
              selectedIcon: const Icon(
                Icons.people_rounded,
                color: AppColors.primary,
              ),
              label: 'Contacts',
            ),

            NavigationDestination(
              icon: Icon(
                Icons.history_rounded,
                color: context.colors.onSurfaceVariant,
              ),
              selectedIcon: const Icon(
                Icons.history_rounded,
                color: AppColors.primary,
              ),
              label: 'Calls',
            ),

            NavigationDestination(
              icon: Icon(
                Icons.person_outline_rounded,
                color: context.colors.onSurfaceVariant,
              ),
              selectedIcon: const Icon(
                Icons.person_rounded,
                color: AppColors.primary,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}