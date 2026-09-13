import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_color_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../models/call_model.dart';
import '../../models/user_model.dart';
import '../../providers/call_provider.dart';
import '../../providers/core_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController =
  TextEditingController();

  late final AnimationController _animationController;

  String _query = '';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid =
        ref.watch(authServiceProvider).currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Center(
          child: Text(
            'Please login again',
            style: TextStyle(
              color: context.colors.onSurface,
            ),
          ),
        ),
      );
    }

    final usersStream =
    ref.watch(userRepositoryProvider).watchContacts(uid);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchField(context),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: usersStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _ErrorState(
                      message:
                      'Unable to search contacts',
                      detail: '${snapshot.error}',
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  final users = _filterUsers(
                    snapshot.data!,
                  );

                  if (_query.isEmpty) {
                    return const _SearchEmptyState(
                      icon: Icons.search_rounded,
                      title: 'Find someone',
                      subtitle:
                      'Search by name or email to find a ConnectCall contact.',
                    );
                  }

                  if (users.isEmpty) {
                    return const _SearchEmptyState(
                      icon: Icons.person_search_rounded,
                      title: 'No contacts found',
                      subtitle:
                      'Try another name or email address.',
                    );
                  }

                  return ListView.builder(
                    physics:
                    const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      4,
                      18,
                      24,
                    ),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      return _SearchContactCard(
                        user: users[index],
                        index: index,
                        onVoiceCall: () => _startCall(
                          context,
                          users[index],
                          CallType.voice,
                        ),
                        onVideoCall: () => _startCall(
                          context,
                          users[index],
                          CallType.video,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        10,
        18,
        8,
      ),
      child: Row(
        children: [
          Material(
            color: context.colors.glassSurface10,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.pop(),
              child: SizedBox(
                width: 46,
                height: 46,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: context.colors.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Search Contacts',
                  style: TextStyle(
                    color: context.colors.onSurface,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Find people on ConnectCall',
                  style: TextStyle(
                    color: context.colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _query.isNotEmpty
                ? AppColors.primaryPulse.withValues(
              alpha: 0.45,
            )
                : context.colors.glassBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPulse.withValues(
                alpha: _query.isNotEmpty ? 0.08 : 0,
              ),
              blurRadius: 20,
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: (value) {
            setState(() {
              _query = value.trim().toLowerCase();
            });
          },
          style: TextStyle(
            color: context.colors.onSurface,
            fontSize: 15,
          ),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: 'Search name or email...',
            hintStyle: TextStyle(
              color: context.colors.onSurfaceVariant
                  .withValues(alpha: 0.55),
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.primary,
            ),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: context.colors.onSurfaceVariant,
              ),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                });
              },
            ),
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(
              vertical: 17,
              horizontal: 10,
            ),
          ),
        ),
      ),
    );
  }

  List<UserModel> _filterUsers(
      List<UserModel> users,
      ) {
    if (_query.isEmpty) return [];

    return users.where((user) {
      final name = user.fullName.toLowerCase();
      final email = user.email?.toLowerCase();

      return name.contains(_query) ||
          email!.contains(_query);
    }).toList();
  }

  Future<void> _startCall(
      BuildContext context,
      UserModel user,
      CallType type,
      ) async {
    try {
      await ref
          .read(callControllerProvider.notifier)
          .startCall(
        calleeId: user.uid,
        chatId: user.uid,
        type: type,
      );

      if (!context.mounted) return;

      context.push('/calls/active');
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.errorContainer,
          content: Text(
            'Call failed: $e',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }
}
class _SearchContactCard extends StatefulWidget {
  const _SearchContactCard({
    required this.user,
    required this.index,
    required this.onVoiceCall,
    required this.onVideoCall,
  });

  final UserModel user;
  final int index;
  final VoidCallback onVoiceCall;
  final VoidCallback onVideoCall;

  @override
  State<_SearchContactCard> createState() =>
      _SearchContactCardState();
}

class _SearchContactCardState
    extends State<_SearchContactCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 450,
      ),
    );

    Future.delayed(
      Duration(milliseconds: widget.index * 60),
          () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = Curves.easeOutCubic.transform(
          _controller.value,
        );

        return Opacity(
          opacity: _controller.value,
          child: Transform.translate(
            offset: Offset(
              0,
              20 * (1 - value),
            ),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer.withValues(
            alpha: 0.82,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.colors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            _Avatar(user: widget.user),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.fullName.isEmpty
                        ? 'User'
                        : widget.user.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.colors.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.user.isOnline
                              ? AppColors.tertiary
                              : AppColors.slate500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.user.isOnline
                            ? 'Online'
                            : 'Offline',
                        style: TextStyle(
                          color: widget.user.isOnline
                              ? AppColors.tertiary
                              : context.colors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _CallButton(
              icon: Icons.call_rounded,
              color: AppColors.tertiary,
              onTap: widget.onVoiceCall,
            ),
            const SizedBox(width: 7),
            _CallButton(
              icon: Icons.videocam_rounded,
              color: AppColors.primaryPulse,
              onTap: widget.onVideoCall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.user,
  });

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final initial = user.fullName.isEmpty
        ? '?'
        : user.fullName[0].toUpperCase();

    return Container(
      width: 54,
      height: 54,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: ClipOval(
        child: user.photoUrl.isNotEmpty
            ? Image.network(
          user.photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _initial(context, initial),
        )
            : _initial(context, initial),
      ),
    );
  }

  Widget _initial(BuildContext context, String initial) {
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

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: color,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryPulse.withValues(
                  alpha: 0.10,
                ),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.onSurface,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.onSurfaceVariant
                    .withValues(alpha: 0.72),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.detail,
  });

  final String message;
  final String detail;

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
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.onSurfaceVariant
                    .withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}