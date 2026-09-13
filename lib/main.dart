import 'package:connect_call_assignment/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/core_providers.dart';
import 'providers/theme_provider.dart';
import 'widgets/callkit_listener.dart';
import 'widgets/fcm_token_sync.dart';
import 'widgets/incoming_call_listener.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  runApp(
    const ProviderScope(
      child: ConnectCallApp(),
    ),
  );
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  if (message.data['type'] == 'call') {
    final notificationService = NotificationService();

    await notificationService.handleIncomingCallData(
      Map<String, dynamic>.from(message.data),
    );
  }
}

class ConnectCallApp extends ConsumerStatefulWidget {
  const ConnectCallApp({super.key});

  @override
  ConsumerState<ConnectCallApp> createState() =>
      _ConnectCallAppState();
}

class _ConnectCallAppState
    extends ConsumerState<ConnectCallApp>
    with WidgetsBindingObserver {
  String? _onlineUid;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _setCurrentUserOnline();

    ref.listenManual(
      authStateProvider,
          (previous, next) {
        final user = next.valueOrNull;

        if (user == null) {
          _onlineUid = null;
          return;
        }

        _setUserOnline(user.uid);
      },
    );
  }

  Future<void> _setCurrentUserOnline() async {
    final user = ref.read(authServiceProvider).currentUser;

    if (user == null) return;

    await _setUserOnline(user.uid);
  }

  Future<void> _setUserOnline(String uid) async {
    try {
      await ref
          .read(userRepositoryProvider)
          .setOnlineStatus(uid, true);

      _onlineUid = uid;

      debugPrint('🟢 USER ONLINE: $uid');
    } catch (e) {
      debugPrint('❌ FAILED TO SET USER ONLINE: $e');
    }
  }

  Future<void> _setUserOffline() async {
    final uid = _onlineUid;

    if (uid == null) return;

    try {
      await ref
          .read(userRepositoryProvider)
          .setOnlineStatus(uid, false);

      debugPrint('🔴 USER OFFLINE: $uid');
    } catch (e) {
      debugPrint('❌ FAILED TO SET USER OFFLINE: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    debugPrint('APP LIFECYCLE: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        _setCurrentUserOnline();
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _setUserOffline();
        break;

      case AppLifecycleState.inactive:
        break;

      case AppLifecycleState.detached:
        _setUserOffline();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp.router(
      title: 'ConnectCall',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(appRouterProvider),
      debugShowCheckedModeBanner: false,
    );

    final incomingCallApp = IncomingCallListener(
      child: app,
    );

    final notificationApp = FcmTokenSync(
      child: kIsWeb
          ? incomingCallApp
          : CallKitListener(
        child: incomingCallApp,
      ),
    );

    return notificationApp;
  }
}