import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PushWorkerService {
  static const String _workerUrl =
      'https://connectcall-push.kashyaprohit9214.workers.dev';

  static Future<void> sendIncomingCall({
    required String callId,
    required String callerId,
    required String calleeId,
    required String callerName,
    String? callerPhotoUrl,
    required String callType,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated');
    }

    final idToken = await user.getIdToken();

    final body = {
      'callId': callId,
      'callerId': callerId,
      'calleeId': calleeId,
      'callerName': callerName,
      'callerPhotoUrl': callerPhotoUrl,
      'callType': callType,
    };

    debugPrint('📤 PUSH WORKER BODY: ${jsonEncode(body)}');
    final response = await http.post(
      Uri.parse(_workerUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Push Worker failed: ${response.statusCode} ${response.body}',
      );
    }
  }
}