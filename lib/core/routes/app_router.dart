import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/call_model.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/complete_profile_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/calls/active_call_screen.dart';
import '../../screens/calls/incoming_call_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/splash/splash_screen.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this._ref) {
    _authSub = _ref.listen<AsyncValue<dynamic>>(
      authStateProvider,
          (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<dynamic>> _authSub;

  @override
  void dispose() {
    _authSub.close();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,

    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),

      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),

      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignupScreen(),
      ),

      GoRoute(
        path: '/complete-profile',
        builder: (_, __) => const CompleteProfileScreen(),
      ),

      GoRoute(
        path: '/',
        builder: (_, __) => const AssignmentHomeScreen(),
      ),

      GoRoute(
        path: '/calls/active',
        builder: (_, __) => const ActiveCallScreen(),
      ),

      GoRoute(
        path: '/calls/incoming',
        builder: (_, state) => IncomingCallScreen(
          call: state.extra! as CallModel,
        ),
      ),

      GoRoute(
        path: '/search',
        builder: (_, __) => const SearchScreen(),
      ),
    ],

    redirect: (_, state) {
      final auth = ref.read(authStateProvider);
      final logged = auth.valueOrNull != null;
      final location = state.matchedLocation;

      if (location == '/splash') {
        return null;
      }

      if (!logged) {
        if (location == '/login' || location == '/signup') {
          return null;
        }

        return '/login';
      }

      if (location == '/login' ||
          location == '/signup' ||
          location == '/complete-profile') {
        return '/';
      }

      return null;
    },
  );

  ref.onDispose(router.dispose);

  return router;
});