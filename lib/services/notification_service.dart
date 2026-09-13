import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _defaultChannel = AndroidNotificationChannel(
  'velvet_hearts_default',
  'Velvet Hearts',
  description: 'Messages, matches, gifts, and orders',
  importance: Importance.high,
);

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (!kIsWeb && Platform.isAndroid) {
      await FlutterCallkitIncoming.requestNotificationPermission({
        'title': 'Incoming calls',
        'rationaleMessagePermission':
            'Notification permission is required to receive incoming calls.',
        'postNotificationMessageRequired':
            'Please allow notification permission in Settings.',
      });
    }

    await _initLocalNotifications();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_defaultChannel);
  }

  Future<String?> getToken() => _messaging.getToken();

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.data['type'] == 'call') {
      handleIncomingCallData(message.data);
      return;
    }

    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _defaultChannel.id,
          _defaultChannel.name,
          channelDescription: _defaultChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload:
          message.data['chatId'] as String? ?? message.data['type'] as String?,
    );
  }

  Future<void> handleIncomingCallData(Map<String, dynamic> data) async {
    final callId = data['callId'] as String?;
    if (callId == null) return;

    final params = CallKitParams(
      id: callId,
      nameCaller: data['callerName'] as String? ?? 'Velvet Hearts',
      appName: 'Velvet Hearts',
      avatar: data['callerPhotoUrl'] as String?,
      handle: data['callerName'] as String? ?? '',
      type: data['callType'] == 'video' ? 1 : 0, // 0 = audio, 1 = video
      duration: 40000, // matches CallController's 40s ring timeout
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: false,
        subtitle: 'Missed call',
      ),
      extra: {'callId': callId, 'callerId': data['callerId'] ?? ''},
      android: const AndroidParams(
        isCustomNotification: false,
        isShowLogo: false,
        ringtonePath: 'discord_incoming_call',
        backgroundColor: '#1E0F12',
        actionColor: '#EE2B6C',
        incomingCallNotificationChannelName: 'Incoming Calls',
        isShowFullLockedScreen: true,
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  Stream<dynamic> get onCallKitEvent => FlutterCallkitIncoming.onEvent;

  Future<void> endCallKitCall(String callId) {
    return FlutterCallkitIncoming.endCall(callId);
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      'notifications_enabled',
      enabled,
    );

    debugPrint(
      enabled
          ? '🔔 Notifications ENABLED'
          : '🔕 Notifications DISABLED',
    );
  }
}

bool get isCallKitAndroidPath => !kIsWeb && Platform.isAndroid;
