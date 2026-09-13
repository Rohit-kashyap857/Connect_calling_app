import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../models/call_model.dart';
import '../providers/call_provider.dart';

class CallActionButtons extends ConsumerWidget {
  const CallActionButtons({
    super.key,
    required this.otherUid,
    required this.chatId,
  });

  final String otherUid;
  final String chatId;

  Future<void> _startCall(BuildContext context, WidgetRef ref, CallType type) async {
    context.push('/calls/active');
    await ref.read(callControllerProvider.notifier).startCall(
          calleeId: otherUid,
          chatId: chatId,
          type: type,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.call_outlined, color: AppColors.primary),
          onPressed: () => _startCall(context, ref, CallType.voice),
        ),
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: AppColors.primary),
          onPressed: () => _startCall(context, ref, CallType.video),
        ),
      ],
    );
  }
}
