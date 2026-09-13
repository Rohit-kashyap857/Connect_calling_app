import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/webrtc_config.dart';

class IceServerService {
  IceServerService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> getIceServers() async {
    try {
      final callable = _functions.httpsCallable('getIceServers');
      final result = await callable.call().timeout(const Duration(seconds: 5));
      final data = result.data;
      if (data is Map && data['iceServers'] is List) {
        return {
          'iceServers': data['iceServers'],
          'sdpSemantics': 'unified-plan',
        };
      }
      throw const FormatException('Unexpected getIceServers response shape');
    } catch (e) {
      debugPrint('IceServerService: falling back to static ICE servers ($e)');
      return WebRtcConfig.staticIceServers;
    }
  }
}
