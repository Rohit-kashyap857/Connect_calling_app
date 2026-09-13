import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../core/constants/webrtc_config.dart';

class WebRtcService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _renderersInitialized = false;

  RTCVideoRenderer get localRenderer => _localRenderer;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isFrontCamera = true;

  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  Future<void> initRenderers() async {
    if (_renderersInitialized) return;
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    _renderersInitialized = true;
  }

  Future<void> initLocalMedia({
    required bool isVideoCall,
    required Map<String, dynamic> iceServers,
  }) async {
    _localStream = await navigator.mediaDevices.getUserMedia(
      isVideoCall
          ? WebRtcConfig.mediaConstraints
          : WebRtcConfig.audioOnlyConstraints,
    );
    _localRenderer.srcObject = _localStream;

    _peerConnection = await createPeerConnection(iceServers);

    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        _remoteRenderer.srcObject = _remoteStream;
      }
    };
  }

  void onIceCandidate(void Function(RTCIceCandidate candidate) callback) {
    _peerConnection?.onIceCandidate = (candidate) {
      if (candidate.candidate != null) callback(candidate);
    };
  }

  void onConnectionStateChange(
      void Function(RTCPeerConnectionState state) callback) {
    _peerConnection?.onConnectionState = callback;
  }

  Future<RTCSessionDescription> createOffer({
    required bool isVideoCall,
    bool iceRestart = false,
  }) async {
    final constraints = {
      ...(isVideoCall
          ? WebRtcConfig.offerSdpConstraints
          : WebRtcConfig.offerSdpConstraintsAudioOnly),
      if (iceRestart) 'iceRestart': true,
    };
    final offer = await _peerConnection!.createOffer(constraints);
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer({required bool isVideoCall}) async {
    final answer = await _peerConnection!.createAnswer(
      isVideoCall
          ? WebRtcConfig.offerSdpConstraints
          : WebRtcConfig.offerSdpConstraintsAudioOnly,
    );
    await _peerConnection!.setLocalDescription(answer);
    return answer;
  }

  Future<RTCSessionDescription> restartIce({required bool isVideoCall}) {
    return createOffer(isVideoCall: isVideoCall, iceRestart: true);
  }

  Future<void> setRemoteDescription(RTCSessionDescription description) {
    return _peerConnection!.setRemoteDescription(description);
  }

  Future<void> addRemoteIceCandidate(RTCIceCandidate candidate) {
    return _peerConnection!.addCandidate(candidate);
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted;
    });
  }

  Future<void> toggleCamera() async {
    _isCameraOff = !_isCameraOff;
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = !_isCameraOff;
    });
  }

  Future<void> switchCamera() async {
    final videoTracks = _localStream?.getVideoTracks() ?? const [];
    if (videoTracks.isEmpty) return;
    await Helper.switchCamera(videoTracks.first);
    _isFrontCamera = !_isFrontCamera;
  }

  bool get isFrontCamera => _isFrontCamera;

  Future<void> setSpeakerphone(bool enabled) async {
    await Helper.setSpeakerphoneOn(enabled);
  }

  Future<void> dispose() async {
    for (final track in _localStream?.getTracks() ?? const <MediaStreamTrack>[]) {
      await track.stop();
    }
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    await _peerConnection?.close();
    await _peerConnection?.dispose();
    if (_renderersInitialized) {
      await _localRenderer.dispose();
      await _remoteRenderer.dispose();
    }
    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
    _isMuted = false;
    _isCameraOff = false;
    _isFrontCamera = true;
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();
    _renderersInitialized = false;
  }
}
