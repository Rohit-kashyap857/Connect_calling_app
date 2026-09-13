import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/call_model.dart';
import '../providers/call_provider.dart';
import '../providers/core_providers.dart';

class CallKitListener extends ConsumerStatefulWidget {
  const CallKitListener({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<CallKitListener> createState() => _CallKitListenerState();
}

class _CallKitListenerState extends ConsumerState<CallKitListener> {
  @override
  void initState() {
    super.initState();
    ref.read(notificationServiceProvider).onCallKitEvent.listen(_handleEvent);
  }

  Future<void> _handleEvent(dynamic event) async {
    if (event is! CallEvent) return;
    final callId = event.body['extra']?['callId'] as String?;
    if (callId == null) return;

    switch (event.event) {
      case Event.actionCallAccept:
        // Fetch the real call doc rather than trusting only the push
        // payload — the call may have already ended/been answered
        // elsewhere between the push arriving and the user tapping
        // Accept.
        final doc = await ref.read(callRepositoryProvider).callDoc(callId).get();
        final data = doc.data();
        if (data == null || data['status'] != CallStatus.ringing.name) {
          await ref.read(notificationServiceProvider).endCallKitCall(callId);
          return;
        }
        final call = CallModel.fromMap(callId, data);

        if (!mounted) return;

        context.push('/calls/active');

        await ref
            .read(callControllerProvider.notifier)
            .answerCall(call);

      case Event.actionCallDecline:
      case Event.actionCallTimeout:
        await ref.read(callRepositoryProvider).updateStatus(
              callId,
              event.event == Event.actionCallTimeout
                  ? CallStatus.missed
                  : CallStatus.declined,
            );

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
