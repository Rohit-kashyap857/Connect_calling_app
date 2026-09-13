import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_router.dart';
import '../../core/theme/app_color_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/call_model.dart';
import '../../providers/call_provider.dart';
import '../../providers/core_providers.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  const IncomingCallScreen({
    super.key,
    required this.call,
  });

  final CallModel call;

  @override
  ConsumerState<IncomingCallScreen> createState() =>
      _IncomingCallScreenState();
}

class _IncomingCallScreenState
    extends ConsumerState<IncomingCallScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _avatarController;
  late final AnimationController _entranceController;
  late final AnimationController _buttonController;

  StreamSubscription? _callStatusSubscription;
  bool _isRemoteCallClosing = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    _watchCallStatus();
  }

  void _watchCallStatus() {
    final repo = ref.read(callRepositoryProvider);

    debugPrint(
      '📞 Incoming screen watching call: ${call.id}',
    );

    _callStatusSubscription = repo.watchCallDoc(call.id).listen(
          (doc) {
        if (!mounted || _isRemoteCallClosing) {
          return;
        }

        final data = doc.data();

        if (!doc.exists || data == null) {
          debugPrint(
            '📞 Incoming call document removed: ${call.id}',
          );

          _closeForRemoteEnd();
          return;
        }

        final status = data['status'] as String?;

        debugPrint(
          '📞 Incoming screen call status: ${call.id} -> $status',
        );

        if (status == CallStatus.ended.name ||
            status == CallStatus.declined.name ||
            status == CallStatus.missed.name) {
          debugPrint(
            '📞 Caller ended call while B was ringing: ${call.id}',
          );

          _closeForRemoteEnd();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          '📞 Incoming screen call listener error: $error',
        );
        debugPrint(
          '📞 Incoming screen call listener stack: $stackTrace',
        );
      },
    );
  }

  void _closeForRemoteEnd() {
    if (_isRemoteCallClosing || !mounted) {
      return;
    }

    _isRemoteCallClosing = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final router = ref.read(appRouterProvider);
      final currentPath = router
          .routerDelegate
          .currentConfiguration
          .uri
          .path;

      debugPrint(
        '📞 Automatic incoming-call close. Current route: $currentPath',
      );

      if (currentPath == '/calls/incoming') {
        router.go('/');
      }
    });
  }

  @override
  void dispose() {
    _callStatusSubscription?.cancel();
    _callStatusSubscription = null;
    _pulseController.dispose();
    _avatarController.dispose();
    _entranceController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  CallModel get call => widget.call;

  @override
  Widget build(BuildContext context) {
    final userStream = ref
        .watch(userRepositoryProvider)
        .watchProfile(call.callerId);

    final isVideoCall = call.type == CallType.video;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: StreamBuilder(
          stream: userStream,
          builder: (context, snapshot) {
            final caller = snapshot.data;

            return AnimatedBuilder(
              animation: _entranceController,
              builder: (context, child) {
                final animation = CurvedAnimation(
                  parent: _entranceController,
                  curve: Curves.easeOutCubic,
                );

                return Opacity(
                  opacity: animation.value,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      35 * (1 - animation.value),
                    ),
                    child: child,
                  ),
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (caller?.photoUrl.isNotEmpty == true)
                    CachedNetworkImage(
                      imageUrl: caller!.photoUrl,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: context.colors.surfaceContainerHigh,
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.30),
                          Colors.black.withValues(alpha: 0.48),
                          Colors.black.withValues(alpha: 0.82),
                        ],
                        stops: const [
                          0.0,
                          0.48,
                          1.0,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.75,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 28,
                      ),
                      child: Column(
                        children: [
                          // Top indicator.
                          _IncomingCallHeader(
                            isVideoCall: isVideoCall,
                          ),

                          const Spacer(flex: 2),
                          _AnimatedIncomingLabel(
                            pulseController: _buttonController,
                            isVideoCall: isVideoCall,
                          ),

                          const SizedBox(height: 28),
                          _CallerAvatar(
                            photoUrl: caller?.photoUrl,
                            pulseController: _pulseController,
                            avatarController: _avatarController,
                          ),

                          const SizedBox(height: 28),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: Text(
                              caller?.fullName ?? 'Calling...',
                              key: ValueKey(
                                caller?.fullName ?? 'Calling...',
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.headlineXl(
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            isVideoCall
                                ? 'Wants to start a video call'
                                : 'Wants to talk with you',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMd(
                              color: Colors.white70,
                            ),
                          ),

                          const Spacer(flex: 2),
                          _CallActions(
                            isVideoCall: isVideoCall,
                            buttonAnimation: _buttonController,
                            onDecline: () async {
                              await ref
                                  .read(callControllerProvider.notifier)
                                  .declineCall(call);

                              if (context.mounted) {
                                context.pop();
                              }
                            },
                            onAccept: () async {
                              await ref
                                  .read(callControllerProvider.notifier)
                                  .answerCall(call);

                              if (context.mounted) {
                                context.pushReplacement(
                                  '/calls/active',
                                );
                              }
                            },
                          ),

                          const SizedBox(height: 22),

                          Text(
                            'Swipe or tap an option',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
class _IncomingCallHeader extends StatelessWidget {
  const _IncomingCallHeader({
    required this.isVideoCall,
  });

  final bool isVideoCall;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            isVideoCall
                ? Icons.videocam_rounded
                : Icons.phone_rounded,
            color: Colors.white70,
            size: 21,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Incoming',
                style: AppTextStyles.bodySm(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedIncomingLabel extends StatelessWidget {
  const _AnimatedIncomingLabel({
    required this.pulseController,
    required this.isVideoCall,
  });

  final AnimationController pulseController;
  final bool isVideoCall;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        final opacity = 0.55 + (pulseController.value * 0.45);

        return Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.30),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVideoCall
                      ? Icons.videocam_rounded
                      : Icons.phone_in_talk_rounded,
                  color: AppColors.primary,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Text(
                  isVideoCall
                      ? 'INCOMING VIDEO CALL'
                      : 'INCOMING VOICE CALL',
                  style: AppTextStyles.labelUppercase(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
class _CallerAvatar extends StatelessWidget {
  const _CallerAvatar({
    required this.photoUrl,
    required this.pulseController,
    required this.avatarController,
  });

  final String? photoUrl;
  final AnimationController pulseController;
  final AnimationController avatarController;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              final value = pulseController.value;

              return Container(
                width: 145 + (value * 70),
                height: 145 + (value * 70),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(
                      alpha: 0.30 * (1 - value),
                    ),
                    width: 2,
                  ),
                ),
              );
            },
          ),

          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              final value = (pulseController.value + 0.5) % 1.0;

              return Container(
                width: 145 + (value * 55),
                height: 145 + (value * 55),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(
                      alpha: 0.20 * (1 - value),
                    ),
                    width: 1.5,
                  ),
                ),
              );
            },
          ),

          AnimatedBuilder(
            animation: avatarController,
            builder: (context, child) {
              final scale = 0.97 + (avatarController.value * 0.03);

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 136,
                  height: 136,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.45),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 35,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: photoUrl != null && photoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: photoUrl!,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      color: context.colors.surfaceContainerHigh,
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 58,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CallActions extends StatelessWidget {
  const _CallActions({
    required this.isVideoCall,
    required this.buttonAnimation,
    required this.onDecline,
    required this.onAccept,
  });

  final bool isVideoCall;
  final AnimationController buttonAnimation;
  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          icon: Icons.call_end_rounded,
          label: 'Decline',
          color: AppColors.error,
          onTap: onDecline,
          isPrimary: false,
          animation: null,
        ),

        const SizedBox(width: 65),
        _ActionButton(
          icon: isVideoCall
              ? Icons.videocam_rounded
              : Icons.call_rounded,
          label: 'Accept',
          color: AppColors.tertiary,
          onTap: onAccept,
          isPrimary: true,
          animation: buttonAnimation,
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isPrimary,
    required this.animation,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isPrimary;
  final AnimationController? animation;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    Widget button = GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
      },
      onTapCancel: () {
        setState(() => _pressed = false);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.38),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: Colors.white,
                size: 31,
              ),
            ),
            const SizedBox(height: 11),
            Text(
              widget.label,
              style: AppTextStyles.bodySm(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.animation != null) {
      button = AnimatedBuilder(
        animation: widget.animation!,
        builder: (context, child) {
          final scale = 1.0 + (widget.animation!.value * 0.045);

          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: button,
      );
    }

    return button;
  }
}