import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/core_providers.dart';

class FcmTokenSync extends ConsumerStatefulWidget {
  const FcmTokenSync({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<FcmTokenSync> createState() => _FcmTokenSyncState();
}

class _FcmTokenSyncState extends ConsumerState<FcmTokenSync> {
  String? _syncedForUid;

  @override
  void initState() {
    super.initState();

    ref.read(notificationServiceProvider).init();

    ref
        .read(notificationServiceProvider)
        .onTokenRefresh
        .listen((token) async {
      final uid =
          ref.read(authServiceProvider).currentUser?.uid;

      if (uid != null) {
        await _syncTokenIfEnabled(uid, token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      final user = next.valueOrNull;

      if (user == null || user.uid == _syncedForUid) {
        return;
      }

      _syncedForUid = user.uid;
      _syncToken(user.uid);
    });

    return widget.child;
  }

  Future<void> _syncToken(String uid) async {
    try {
      debugPrint('🔵 FCM SYNC START');
      debugPrint('🔵 UID: $uid');

      final token =
      await ref.read(notificationServiceProvider).getToken();

      debugPrint('🟢 FCM TOKEN: $token');

      if (token == null || token.isEmpty) {
        debugPrint('🔴 FCM TOKEN IS NULL/EMPTY');
        return;
      }

      await _syncTokenIfEnabled(uid, token);
    } catch (e, stackTrace) {
      debugPrint('❌ FCM TOKEN SYNC ERROR: $e');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _syncTokenIfEnabled(
      String uid,
      String token,
      ) async {
    final enabled =
    await ref.read(notificationServiceProvider).areNotificationsEnabled();

    if (!enabled) {
      debugPrint('🔕 Notifications OFF - token not saved');
      return;
    }

    await ref
        .read(userRepositoryProvider)
        .addFcmToken(uid, token);

    debugPrint('✅ FCM TOKEN SAVED TO FIRESTORE');
  }
}
