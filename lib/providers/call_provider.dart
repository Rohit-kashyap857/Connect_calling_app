import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

import '../models/call_model.dart';
import '../repositories/call_repository.dart';
import '../services/push_worker_service.dart';
import '../services/webrtc_service.dart';
import 'auth_provider.dart';
import 'core_providers.dart';

enum CallConnectionPhase {
  idle,
  connecting,
  ringing,
  ongoing,
  reconnecting,
  ended,
}

const _ringTimeout = Duration(seconds: 40);
const _reconnectGracePeriod = Duration(seconds: 6);

class CallSessionState {
  final CallModel? call;
  final CallConnectionPhase phase;
  final bool isMuted;
  final bool isCameraOff;
  final bool isSpeakerOn;
  final int elapsedSeconds;
  final String? errorMessage;
  final String? sessionId;

  const CallSessionState({
    this.call,
    this.phase = CallConnectionPhase.idle,
    this.isMuted = false,
    this.isCameraOff = false,
    this.isSpeakerOn = true,
    this.elapsedSeconds = 0,
    this.errorMessage,
    this.sessionId,
  });

  CallSessionState copyWith({
    CallModel? call,
    CallConnectionPhase? phase,
    bool? isMuted,
    bool? isCameraOff,
    bool? isSpeakerOn,
    int? elapsedSeconds,
    String? errorMessage,
    String? sessionId,
    bool clearSessionId = false,
  }) {
    return CallSessionState(
      call: call ?? this.call,
      phase: phase ?? this.phase,
      isMuted: isMuted ?? this.isMuted,
      isCameraOff: isCameraOff ?? this.isCameraOff,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      errorMessage: errorMessage,
      sessionId: clearSessionId
          ? null
          : (sessionId ?? this.sessionId),
    );
  }
}

class CallController extends StateNotifier<CallSessionState> {
  CallController(this._ref) : super(const CallSessionState());

  final Ref _ref;
  final WebRtcService webrtc = WebRtcService();
  final _uuid = const Uuid();

  StreamSubscription? _callDocSub;
  StreamSubscription? _remoteCandidatesSub;

  Timer? _timer;
  Timer? _ringTimeoutTimer;
  Timer? _reconnectTimer;

  bool _iAmCaller = false;
  bool _isVideoCall = false;

  int _iceRestartRequestId = 0;
  int _lastAppliedIceRestartRequestId = 0;
  int _lastAppliedIceRestartAnswerId = 0;

  String get _myUid =>
      _ref.read(authServiceProvider).currentUser?.uid ?? '';

  bool _isCurrentSession(String? sessionId) {
    return sessionId != null && sessionId == state.sessionId;
  }

  Future<void> startCall({
    required String calleeId,
    required String chatId,
    required CallType type,
  }) async {
    final sessionId = _uuid.v4();

    _iAmCaller = true;
    _isVideoCall = type == CallType.video;

    state = state.copyWith(
      phase: CallConnectionPhase.connecting,
      sessionId: sessionId,
      errorMessage: null,
    );

    final iceServers =
    await _ref.read(iceServerServiceProvider).getIceServers();

    if (!_isCurrentSession(sessionId)) return;

    await webrtc.initRenderers();

    await webrtc.initLocalMedia(
      isVideoCall: _isVideoCall,
      iceServers: iceServers,
    );

    if (!_isCurrentSession(sessionId)) return;

    final repo = _ref.read(callRepositoryProvider);

    final callId = await repo.createCall(
      callerId: _myUid,
      calleeId: calleeId,
      chatId: chatId,
      type: type,
    );

    try {
      debugPrint('CALLING PUSH WORKER...');

      await PushWorkerService.sendIncomingCall(
        callId: callId,
        callerId: _myUid,
        calleeId: calleeId,
        callerName: _myUid,
        callType: type == CallType.video
            ? 'video'
            : 'audio',
      );

      debugPrint('PUSH WORKER SUCCESS');
    } catch (e, stackTrace) {
      debugPrint('PUSH WORKER ERROR: $e');
      debugPrint('PUSH WORKER STACK: $stackTrace');
    }

    if (!_isCurrentSession(sessionId)) return;
    webrtc.onIceCandidate((candidate) {
      unawaited(
        repo.addCandidate(
          callId: callId,
          isCaller: true,
          candidate: candidate.toMap(),
        ),
      );
    });

    _listenForReconnects(
      repo,
      callId,
      sessionId,
    );
    final offer = await webrtc.createOffer(
      isVideoCall: _isVideoCall,
    );

    if (!_isCurrentSession(sessionId)) return;

    await repo.setOffer(
      callId,
      {
        'sdp': offer.sdp,
        'type': offer.type,
      },
    );

    if (!_isCurrentSession(sessionId)) return;

    state = state.copyWith(
      phase: CallConnectionPhase.ringing,
      call: CallModel(
        id: callId,
        callerId: _myUid,
        calleeId: calleeId,
        chatId: chatId,
        type: type,
        status: CallStatus.ringing,
        createdAt: DateTime.now(),
      ),
    );

    _armRingTimeout(
      repo,
      callId,
      sessionId,
    );

    _watchCallDoc(
      callId,
      repo,
      sessionId,
    );

    _watchRemoteCandidates(
      callId,
      repo,
      isCaller: true,
      sessionId: sessionId,
    );
  }

  void _armRingTimeout(
      CallRepository repo,
      String callId,
      String sessionId,
      ) {
    _ringTimeoutTimer?.cancel();

    _ringTimeoutTimer = Timer(
      _ringTimeout,
          () async {
        if (_isCurrentSession(sessionId) &&
            state.phase == CallConnectionPhase.ringing) {
          await repo.updateStatus(
            callId,
            CallStatus.missed,
          );

          await _endSession(callId);
        }
      },
    );
  }

  Future<void> answerCall(CallModel call) async {
    final sessionId = _uuid.v4();

    _iAmCaller = false;
    _isVideoCall = call.type == CallType.video;

    state = state.copyWith(
      call: call,
      phase: CallConnectionPhase.connecting,
      sessionId: sessionId,
      errorMessage: null,
    );

    final iceServers =
    await _ref.read(iceServerServiceProvider).getIceServers();

    if (!_isCurrentSession(sessionId)) return;

    await webrtc.initRenderers();

    await webrtc.initLocalMedia(
      isVideoCall: _isVideoCall,
      iceServers: iceServers,
    );

    if (!_isCurrentSession(sessionId)) return;

    final repo = _ref.read(callRepositoryProvider);

    final doc = await repo.callDoc(call.id).get();

    if (!_isCurrentSession(sessionId)) return;

    final offerMap =
    doc.data()?['offer'] as Map<String, dynamic>?;

    if (offerMap == null) {
      state = state.copyWith(
        phase: CallConnectionPhase.ended,
        errorMessage: 'Call offer missing',
      );

      return;
    }
    webrtc.onIceCandidate((candidate) {
      unawaited(
        repo.addCandidate(
          callId: call.id,
          isCaller: false,
          candidate: candidate.toMap(),
        ),
      );
    });

    _listenForReconnects(
      repo,
      call.id,
      sessionId,
    );
    await webrtc.setRemoteDescription(
      RTCSessionDescription(
        offerMap['sdp'] as String,
        offerMap['type'] as String,
      ),
    );

    if (!_isCurrentSession(sessionId)) return;
    final answer = await webrtc.createAnswer(
      isVideoCall: _isVideoCall,
    );

    if (!_isCurrentSession(sessionId)) return;

    await repo.setAnswer(
      call.id,
      {
        'sdp': answer.sdp,
        'type': answer.type,
      },
    );

    if (!_isCurrentSession(sessionId)) return;

    state = state.copyWith(
      phase: CallConnectionPhase.ongoing,
    );

    _startTimer(sessionId);

    _watchCallDoc(
      call.id,
      repo,
      sessionId,
    );

    _watchRemoteCandidates(
      call.id,
      repo,
      isCaller: false,
      sessionId: sessionId,
    );
  }

  void _watchCallDoc(
      String callId,
      CallRepository repo,
      String sessionId,
      ) {
    _callDocSub?.cancel();

    _callDocSub = repo.watchCallDoc(callId).listen(
          (
          DocumentSnapshot<Map<String, dynamic>> doc,
          ) async {
        if (!_isCurrentSession(sessionId)) return;

        final data = doc.data();

        if (data == null) return;
        if (_iAmCaller &&
            data['answer'] != null &&
            state.phase == CallConnectionPhase.ringing) {
          _ringTimeoutTimer?.cancel();

          final answerMap =
          data['answer'] as Map<String, dynamic>;

          await webrtc.setRemoteDescription(
            RTCSessionDescription(
              answerMap['sdp'] as String,
              answerMap['type'] as String,
            ),
          );

          if (!_isCurrentSession(sessionId)) return;

          state = state.copyWith(
            phase: CallConnectionPhase.ongoing,
          );

          _startTimer(sessionId);
        }
        if (!_iAmCaller &&
            data['iceRestartRequestId'] != null &&
            (data['iceRestartRequestId'] as int) >
                _lastAppliedIceRestartRequestId &&
            data['iceRestartOffer'] != null) {
          final requestId =
          data['iceRestartRequestId'] as int;

          _lastAppliedIceRestartRequestId = requestId;

          final offerMap =
          data['iceRestartOffer'] as Map<String, dynamic>;

          await webrtc.setRemoteDescription(
            RTCSessionDescription(
              offerMap['sdp'] as String,
              offerMap['type'] as String,
            ),
          );

          if (!_isCurrentSession(sessionId)) return;

          final answer = await webrtc.createAnswer(
            isVideoCall: _isVideoCall,
          );

          if (!_isCurrentSession(sessionId)) return;

          await repo.callDoc(callId).update({
            'iceRestartAnswer': {
              'sdp': answer.sdp,
              'type': answer.type,
            },
            'iceRestartAnswerForId': requestId,
          });
        }
        if (_iAmCaller &&
            data['iceRestartAnswerForId'] != null &&
            (data['iceRestartAnswerForId'] as int) ==
                _iceRestartRequestId &&
            (data['iceRestartAnswerForId'] as int) >
                _lastAppliedIceRestartAnswerId &&
            data['iceRestartAnswer'] != null) {
          _lastAppliedIceRestartAnswerId =
          data['iceRestartAnswerForId'] as int;

          final answerMap =
          data['iceRestartAnswer'] as Map<String, dynamic>;

          await webrtc.setRemoteDescription(
            RTCSessionDescription(
              answerMap['sdp'] as String,
              answerMap['type'] as String,
            ),
          );
        }
        final status = data['status'] as String?;

        if (status == CallStatus.declined.name ||
            status == CallStatus.ended.name ||
            status == CallStatus.missed.name) {
          await _endSession(callId);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          'Call document listener error: $error',
        );

        debugPrint(
          'Call document listener stack: $stackTrace',
        );
      },
    );
  }

  void _watchRemoteCandidates(
      String callId,
      CallRepository repo, {
        required bool isCaller,
        required String sessionId,
      }) {
    _remoteCandidatesSub?.cancel();

    _remoteCandidatesSub = repo
        .watchRemoteCandidates(
      callId: callId,
      isCaller: isCaller,
    )
        .listen(
          (List<Map<String, dynamic>> candidates) {
        if (!_isCurrentSession(sessionId)) return;

        for (final c in candidates) {
          unawaited(
            webrtc.addRemoteIceCandidate(
              RTCIceCandidate(
                c['candidate'] as String?,
                c['sdpMid'] as String?,
                c['sdpMLineIndex'] as int?,
              ),
            ),
          );
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          'Remote ICE candidate error: $error',
        );

        debugPrint(
          'Remote ICE candidate stack: $stackTrace',
        );
      },
    );
  }

  void _listenForReconnects(
      CallRepository repo,
      String callId,
      String sessionId,
      ) {
    webrtc.onConnectionStateChange(
          (rtcState) {
        if (!_isCurrentSession(sessionId)) return;

        if (rtcState ==
            RTCPeerConnectionState
                .RTCPeerConnectionStateDisconnected) {
          state = state.copyWith(
            phase: CallConnectionPhase.reconnecting,
          );

          _reconnectTimer?.cancel();

          _reconnectTimer = Timer(
            _reconnectGracePeriod,
                () {
              if (_isCurrentSession(sessionId) &&
                  state.phase ==
                      CallConnectionPhase.reconnecting &&
                  _iAmCaller) {
                attemptIceRestart(
                  repo,
                  callId,
                );
              }
            },
          );
        } else if (rtcState ==
            RTCPeerConnectionState
                .RTCPeerConnectionStateConnected) {
          _reconnectTimer?.cancel();

          if (state.phase ==
              CallConnectionPhase.reconnecting) {
            state = state.copyWith(
              phase: CallConnectionPhase.ongoing,
            );
          }
        } else if (rtcState ==
            RTCPeerConnectionState
                .RTCPeerConnectionStateFailed) {
          _reconnectTimer?.cancel();

          unawaited(
            _endSession(callId),
          );
        }
      },
    );
  }

  Future<void> attemptIceRestart(
      CallRepository repo,
      String callId,
      ) async {
    try {
      final newOffer = await webrtc.restartIce(
        isVideoCall: _isVideoCall,
      );

      _iceRestartRequestId += 1;

      await repo.callDoc(callId).update({
        'iceRestartOffer': {
          'sdp': newOffer.sdp,
          'type': newOffer.type,
        },
        'iceRestartRequestId':
        _iceRestartRequestId,
      });
    } catch (e) {
      debugPrint(
        'ICE restart failed: $e',
      );
    }
  }

  void _startTimer(String sessionId) {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (!_isCurrentSession(sessionId)) return;

        state = state.copyWith(
          elapsedSeconds: state.elapsedSeconds + 1,
        );

        final call = state.call;

        if (call != null &&
            state.elapsedSeconds % 5 == 0) {
          unawaited(
            _ref
                .read(callRepositoryProvider)
                .setDuration(
              call.id,
              state.elapsedSeconds,
            ),
          );
        }
      },
    );
  }

  Future<void> declineCall(CallModel call) async {
    await _ref
        .read(callRepositoryProvider)
        .updateStatus(
      call.id,
      CallStatus.declined,
    );

    await _endSession(call.id);
  }

  Future<void> endCall() async {
    final call = state.call;

    if (call != null) {
      final repo = _ref.read(callRepositoryProvider);
      await repo.updateStatus(
        call.id,
        CallStatus.ended,
      );

      unawaited(
        repo.setDuration(
          call.id,
          state.elapsedSeconds,
        ),
      );
      unawaited(
        repo.cleanupCandidates(call.id),
      );
    }

    await _endSession(call?.id);
  }

  Future<void> _endSession(String? callId) async {
    _timer?.cancel();
    _ringTimeoutTimer?.cancel();
    _reconnectTimer?.cancel();

    await _callDocSub?.cancel();
    await _remoteCandidatesSub?.cancel();

    _callDocSub = null;
    _remoteCandidatesSub = null;

    await webrtc.dispose();

    if (callId != null) {
      try {
        await _ref
            .read(notificationServiceProvider)
            .endCallKitCall(callId);
      } catch (_) {}
    }

    state = state.copyWith(
      phase: CallConnectionPhase.ended,
      clearSessionId: true,
    );
  }

  Future<void> toggleMute() async {
    await webrtc.toggleMute();

    state = state.copyWith(
      isMuted: webrtc.isMuted,
    );
  }

  Future<void> toggleCamera() async {
    await webrtc.toggleCamera();

    state = state.copyWith(
      isCameraOff: webrtc.isCameraOff,
    );
  }

  Future<void> switchCamera() async {
    await webrtc.switchCamera();
  }

  Future<void> toggleSpeaker() async {
    final next = !state.isSpeakerOn;

    await webrtc.setSpeakerphone(next);

    state = state.copyWith(
      isSpeakerOn: next,
    );
  }

  void reset() {
    _iceRestartRequestId = 0;
    _lastAppliedIceRestartRequestId = 0;
    _lastAppliedIceRestartAnswerId = 0;

    state = const CallSessionState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringTimeoutTimer?.cancel();
    _reconnectTimer?.cancel();

    _callDocSub?.cancel();
    _remoteCandidatesSub?.cancel();

    unawaited(
      webrtc.dispose(),
    );

    super.dispose();
  }
}

final callControllerProvider =
StateNotifierProvider<CallController, CallSessionState>(
      (ref) => CallController(ref),
);


final incomingCallProvider =
StreamProvider<CallModel?>((ref) {
  final myUid =
      ref.watch(authStateProvider).valueOrNull?.uid;

  if (myUid == null) {
    return Stream<CallModel?>.value(null);
  }

  return ref
      .watch(callRepositoryProvider)
      .watchIncomingCall(myUid);
});

final callHistoryProvider =
StreamProvider<List<CallModel>>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    loading: () {
      return Stream.value(
        const <CallModel>[],
      );
    },

    error: (_, __) {
      return Stream.value(
        const <CallModel>[],
      );
    },

    data: (user) {
      if (user == null) {
        return Stream.value(
          const <CallModel>[],
        );
      }
      return ref
          .watch(callRepositoryProvider)
          .watchCallHistory(user.uid);
    },
  );
});