import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/routes/app_router.dart';
import '../models/call_model.dart';
import '../providers/call_provider.dart';
import '../providers/core_providers.dart';

class IncomingCallListener extends ConsumerStatefulWidget {
  const IncomingCallListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<IncomingCallListener> createState() =>
      _IncomingCallListenerState();
}

class _IncomingCallListenerState
    extends ConsumerState<IncomingCallListener> {
  String? _activeIncomingCallId;

  StreamSubscription? _callDocSubscription;

  ProviderSubscription<AsyncValue<CallModel?>>? _incomingCallSubscription;

  bool _isClosingIncomingCall = false;

  @override
  void initState() {
    super.initState();

    // Listen only ONCE for incoming calls.
    _incomingCallSubscription = ref.listenManual<AsyncValue<CallModel?>>(
      incomingCallProvider,
          (previous, next) {
        _handleIncomingCallUpdate(next);
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _callDocSubscription?.cancel();
    _callDocSubscription = null;

    _incomingCallSubscription?.close();
    _incomingCallSubscription = null;

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // HANDLE INCOMING CALL PROVIDER
  // ---------------------------------------------------------------------------

  void _handleIncomingCallUpdate(
      AsyncValue<CallModel?> next,
      ) {
    if (!mounted) return;

    debugPrint(
      '📞 IncomingCallListener update: $next',
    );

    // -------------------------------------------------------------------------
    // PROVIDER LOADING / ERROR
    // -------------------------------------------------------------------------

    if (!next.hasValue) {
      return;
    }

    final call = next.value;

    debugPrint(
      '📞 Incoming call: ${call?.id}, '
          'status: ${call?.status}',
    );

    // -------------------------------------------------------------------------
    // NO INCOMING CALL
    // -------------------------------------------------------------------------

    if (call == null) {
      final previousCallId = _activeIncomingCallId;

      if (previousCallId == null) {
        return;
      }

      debugPrint(
        '📞 Provider says call ended: $previousCallId',
      );

      unawaited(
        _closeIncomingCall(previousCallId),
      );

      return;
    }

    // -------------------------------------------------------------------------
    // SAME CALL
    // -------------------------------------------------------------------------

    if (call.id == _activeIncomingCallId) {
      return;
    }

    // -------------------------------------------------------------------------
    // NEW INCOMING CALL
    // -------------------------------------------------------------------------

    _activeIncomingCallId = call.id;
    _isClosingIncomingCall = false;

    final router = ref.read(appRouterProvider);

    final currentPath = router
        .routerDelegate
        .currentConfiguration
        .uri
        .path;

    debugPrint(
      '📞 New incoming call: ${call.id}',
    );

    // -------------------------------------------------------------------------
    // WATCH EXACT CALL DOCUMENT
    // -------------------------------------------------------------------------

    unawaited(
      _watchSpecificCall(call),
    );

    // -------------------------------------------------------------------------
    // ALREADY ON INCOMING SCREEN
    // -------------------------------------------------------------------------

    if (currentPath == '/calls/incoming') {
      return;
    }

    debugPrint(
      '📞 Opening incoming call screen: ${call.id}',
    );

    // -------------------------------------------------------------------------
    // OPEN INCOMING SCREEN
    // -------------------------------------------------------------------------

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_activeIncomingCallId != call.id) {
        return;
      }

      final latestRouter = ref.read(appRouterProvider);

      final latestPath = latestRouter
          .routerDelegate
          .currentConfiguration
          .uri
          .path;

      if (latestPath == '/calls/incoming') {
        return;
      }

      debugPrint(
        '📞 Pushing incoming call screen: ${call.id}',
      );

      latestRouter.push(
        '/calls/incoming',
        extra: call,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // WATCH EXACT CALL DOCUMENT
  // ---------------------------------------------------------------------------

  Future<void> _watchSpecificCall(CallModel call) async {
    await _callDocSubscription?.cancel();

    if (!mounted) return;

    final repo = ref.read(callRepositoryProvider);

    debugPrint(
      '📞 Starting direct call listener: ${call.id}',
    );

    _callDocSubscription = repo.watchCallDoc(call.id).listen(
          (doc) {
        if (!mounted) return;

        final data = doc.data();

        // ---------------------------------------------------------------------
        // CALL DOCUMENT DELETED
        // ---------------------------------------------------------------------

        if (!doc.exists || data == null) {
          debugPrint(
            '📞 Call document removed: ${call.id}',
          );

          unawaited(
            _closeIncomingCall(call.id),
          );

          return;
        }

        final status = data['status'] as String?;

        debugPrint(
          '📞 Direct call status: ${call.id} -> $status',
        );

        // ---------------------------------------------------------------------
        // REMOTE CALL ENDED
        // ---------------------------------------------------------------------

        if (status == CallStatus.ended.name ||
            status == CallStatus.declined.name ||
            status == CallStatus.missed.name) {
          debugPrint(
            '📞 Remote call ended: ${call.id}',
          );

          unawaited(
            _closeIncomingCall(call.id),
          );
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          '📞 Direct call listener error: $error',
        );

        debugPrint(
          '📞 Direct call listener stack: $stackTrace',
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // CLOSE INCOMING CALL SCREEN
  // ---------------------------------------------------------------------------

  Future<void> _closeIncomingCall(String callId) async {
    // Already closing.
    if (_isClosingIncomingCall) {
      return;
    }

    // Ignore old/irrelevant calls.
    if (_activeIncomingCallId != callId) {
      return;
    }

    _isClosingIncomingCall = true;

    debugPrint(
      '📞 Closing incoming call UI: $callId',
    );

    _activeIncomingCallId = null;

    // Stop the direct Firestore listener.
    final subscription = _callDocSubscription;
    _callDocSubscription = null;

    await subscription?.cancel();

    if (!mounted) {
      return;
    }

    final router = ref.read(appRouterProvider);

    // -------------------------------------------------------------------------
    // NAVIGATE TO HOME AFTER FIRESTORE CALLBACK FINISHES
    // -------------------------------------------------------------------------

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final latestRouter = ref.read(appRouterProvider);

      final latestPath = latestRouter
          .routerDelegate
          .currentConfiguration
          .uri
          .path;

      debugPrint(
        '📞 Route before automatic close: $latestPath',
      );

      // If the incoming screen is still the active route,
      // force the app back to Home.
      if (latestPath == '/calls/incoming') {
        debugPrint(
          '📞 Remote caller ended call. Returning callee to Home.',
        );

        latestRouter.go('/');

        debugPrint(
          '📞 Callee returned to Home automatically.',
        );
      }

      _isClosingIncomingCall = false;
    });
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}