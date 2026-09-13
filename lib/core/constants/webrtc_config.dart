class WebRtcConfig {
  WebRtcConfig._();

  static const Map<String, dynamic> staticIceServers = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
        ],
      },
      {
        'urls': ['turn:REPLACE_WITH_YOUR_TURN_SERVER:3478'],
        'username': 'REPLACE_WITH_TURN_USERNAME',
        'credential': 'REPLACE_WITH_TURN_CREDENTIAL',
      },
    ],
    'sdpSemantics': 'unified-plan',
  };

  static const Map<String, dynamic> mediaConstraints = {
    'audio': true,
    'video': {
      'facingMode': 'user',
      'width': {'ideal': 640},
      'height': {'ideal': 480},
    },
  };

  static const Map<String, dynamic> audioOnlyConstraints = {
    'audio': true,
    'video': false,
  };

  static const Map<String, dynamic> offerSdpConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  static const Map<String, dynamic> offerSdpConstraintsAudioOnly = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': false,
    },
    'optional': [],
  };
}
