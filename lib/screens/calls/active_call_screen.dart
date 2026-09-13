import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_color_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/call_model.dart';
import '../../providers/call_provider.dart';
import '../../providers/core_providers.dart';

class ActiveCallScreen extends ConsumerStatefulWidget {
  const ActiveCallScreen({super.key});

  @override
  ConsumerState<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _avatarController;
  late final AnimationController _fadeController;

  ProviderSubscription<CallSessionState>? _callStateSubscription;

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

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _callStateSubscription = ref.listenManual<CallSessionState>(
      callControllerProvider,
          (previous, next) {
        if (next.phase != CallConnectionPhase.ended) {
          return;
        }

        if (!mounted) {
          return;
        }

        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }

        ref.read(callControllerProvider.notifier).reset();
      },
    );
  }

  @override
  void dispose() {
    _callStateSubscription?.close();
    _callStateSubscription = null;

    _pulseController.dispose();
    _avatarController.dispose();
    _fadeController.dispose();

    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(callControllerProvider);
    final controller = ref.read(callControllerProvider.notifier);
    final myUid = ref.watch(authServiceProvider).currentUser?.uid ?? '';
    final call = session.call;

    if (call == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    final otherUid = call.otherUid(myUid);
    final isVideoCall = call.type == CallType.video;

    final userStream =
    ref.watch(userRepositoryProvider).watchProfile(otherUid);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: StreamBuilder(
          stream: userStream,
          builder: (context, snapshot) {
            final otherUser = snapshot.data;

            return AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeController.value,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      20 * (1 - _fadeController.value),
                    ),
                    child: child,
                  ),
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isVideoCall &&
                      session.phase == CallConnectionPhase.ongoing)
                    RTCVideoView(
                      controller.webrtc.remoteRenderer,
                      objectFit: RTCVideoViewObjectFit
                          .RTCVideoViewObjectFitCover,
                    )
                  else
                    _AudioCallBackground(
                      photoUrl: otherUser?.photoUrl,
                      animation: _pulseController,
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.45),
                          Colors.black.withValues(alpha: 0.78),
                        ],
                        stops: const [
                          0.0,
                          0.45,
                          1.0,
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          _TopGlassButton(
                            icon: Icons.keyboard_arrow_down_rounded,
                            onTap: () {},
                          ),
                          const Spacer(),
                          _CallTypeBadge(
                            isVideoCall: isVideoCall,
                          ),
                        ],
                      ),
                    ),),
                  if (isVideoCall)
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 76,
                            right: 16,
                          ),
                          child: _LocalVideoPreview(
                            renderer: controller.webrtc.localRenderer,
                          ),
                        ),
                      ),
                    ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: Column(
                        children: [
                          const Spacer(flex: 2),
                          _AnimatedCallerAvatar(
                            photoUrl: otherUser?.photoUrl,
                            name: otherUser?.fullName ?? 'User',
                            pulseAnimation: _pulseController,
                            avatarAnimation: _avatarController,
                          ),

                          const SizedBox(height: 24),

                          // Name.
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              otherUser?.fullName ?? 'Connecting...',
                              key: ValueKey(
                                otherUser?.fullName ?? 'Connecting...',
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

                          // Status.
                          _AnimatedCallStatus(
                            phase: session.phase,
                            elapsedSeconds: session.elapsedSeconds,
                            formatDuration: _formatDuration,
                          ),

                          const Spacer(flex: 2),
                          _ControlsPanel(
                            isVideoCall: isVideoCall,
                            session: session,
                            controller: controller,
                          ),

                          const SizedBox(height: 18),
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

class _AudioCallBackground extends StatelessWidget {
  const _AudioCallBackground({
    required this.photoUrl,
    required this.animation,
  });

  final String? photoUrl;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (photoUrl != null && photoUrl!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: photoUrl!,
            fit: BoxFit.cover,
          )
        else
          Container(
            color: context.colors.surfaceContainerHigh,
          ),

        if (photoUrl != null && photoUrl!.isNotEmpty)
          BackdropFilter(
            filter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.25),
              BlendMode.darken,
            ),
            child: Container(),
          ),

        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final scale = 1.0 + (animation.value * 0.08);

            return Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AnimatedCallerAvatar extends StatelessWidget {
  const _AnimatedCallerAvatar({
    required this.photoUrl,
    required this.name,
    required this.pulseAnimation,
    required this.avatarAnimation,
  });

  final String? photoUrl;
  final String name;
  final Animation<double> pulseAnimation;
  final Animation<double> avatarAnimation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring.
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              final value = pulseAnimation.value;

              return Container(
                width: 150 + (value * 40),
                height: 150 + (value * 40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(
                      alpha: 0.28 * (1 - value),
                    ),
                    width: 2,
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              final value = (pulseAnimation.value + 0.5) % 1.0;

              return Container(
                width: 145 + (value * 28),
                height: 145 + (value * 28),
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
            animation: avatarAnimation,
            builder: (context, child) {
              final scale = 0.97 + (avatarAnimation.value * 0.03);

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 128,
                  height: 128,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.55),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 30,
                        spreadRadius: 3,
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
                        size: 54,
                        color: Colors.white,
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

class _AnimatedCallStatus extends StatelessWidget {
  const _AnimatedCallStatus({
    required this.phase,
    required this.elapsedSeconds,
    required this.formatDuration,
  });

  final CallConnectionPhase phase;
  final int elapsedSeconds;
  final String Function(int) formatDuration;

  String get label {
    switch (phase) {
      case CallConnectionPhase.connecting:
        return 'Connecting...';

      case CallConnectionPhase.ringing:
        return 'Ringing...';

      case CallConnectionPhase.reconnecting:
        return 'Reconnecting...';

      case CallConnectionPhase.ongoing:
        return formatDuration(elapsedSeconds);

      case CallConnectionPhase.ended:
        return 'Call ended';

      case CallConnectionPhase.idle:
        return '';
    }
  }

  IconData get icon {
    switch (phase) {
      case CallConnectionPhase.connecting:
        return Icons.sync_rounded;

      case CallConnectionPhase.ringing:
        return Icons.phone_in_talk_rounded;

      case CallConnectionPhase.reconnecting:
        return Icons.wifi_tethering_error_rounded;

      case CallConnectionPhase.ongoing:
        return Icons.graphic_eq_rounded;

      case CallConnectionPhase.ended:
        return Icons.call_end_rounded;

      case CallConnectionPhase.idle:
        return Icons.phone_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.92,
              end: 1,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey('$phase-$elapsedSeconds'),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.white70,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: AppTextStyles.bodyMd(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopGlassButton extends StatelessWidget {
  const _TopGlassButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
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
            icon,
            color: Colors.white,
            size: 25,
          ),
        ),
      ),
    );
  }
}

class _CallTypeBadge extends StatelessWidget {
  const _CallTypeBadge({
    required this.isVideoCall,
  });

  final bool isVideoCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
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
          Icon(
            isVideoCall
                ? Icons.videocam_rounded
                : Icons.phone_rounded,
            size: 16,
            color: Colors.white70,
          ),
          const SizedBox(width: 7),
          Text(
            isVideoCall ? 'Video call' : 'Voice call',
            style: AppTextStyles.bodySm(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
class _LocalVideoPreview extends StatelessWidget {
  const _LocalVideoPreview({
    required this.renderer,
  });

  final RTCVideoRenderer renderer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 142,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            RTCVideoView(
              renderer,
              mirror: true,
              objectFit:
              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({
    required this.isVideoCall,
    required this.session,
    required this.controller,
  });

  final bool isVideoCall;
  final CallSessionState session;
  final CallController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ControlButton(
            icon: session.isMuted
                ? Icons.mic_off_rounded
                : Icons.mic_rounded,
            label: session.isMuted ? 'Muted' : 'Mute',
            active: session.isMuted,
            onTap: controller.toggleMute,
          ),

          const SizedBox(width: 12),

          if (isVideoCall)
            _ControlButton(
              icon: session.isCameraOff
                  ? Icons.videocam_off_rounded
                  : Icons.videocam_rounded,
              label: session.isCameraOff ? 'Camera off' : 'Camera',
              active: session.isCameraOff,
              onTap: controller.toggleCamera,
            )
          else
            _ControlButton(
              icon: session.isSpeakerOn
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              label: session.isSpeakerOn ? 'Speaker' : 'Speaker off',
              active: !session.isSpeakerOn,
              onTap: controller.toggleSpeaker,
            ),

          if (isVideoCall) ...[
            const SizedBox(width: 12),
            _ControlButton(
              icon: Icons.cameraswitch_rounded,
              label: 'Flip',
              active: false,
              onTap: controller.switchCamera,
            ),
          ],

          const SizedBox(width: 18),

          _EndCallButton(
            onTap: controller.endCall,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(25),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.13),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: active ? 0.28 : 0.10,
                  ),
                ),
                boxShadow: active
                    ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: 0.30,
                    ),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
                    : null,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: Icon(
                  icon,
                  key: ValueKey(icon),
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EndCallButton extends StatefulWidget {
  const _EndCallButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<_EndCallButton> createState() => _EndCallButtonState();
}

class _EndCallButtonState extends State<_EndCallButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.35),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.call_end_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}