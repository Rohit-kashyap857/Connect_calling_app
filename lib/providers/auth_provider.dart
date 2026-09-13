import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'core_providers.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(userRepositoryProvider).watchProfile(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _ref.read(authServiceProvider).signInWithEmail(
            email: email,
            password: password,
          );
    });
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final auth = _ref.read(authServiceProvider);

      final credential = await auth.signUpWithEmail(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      await _ref.read(userRepositoryProvider).createProfile(
        UserModel(
          uid: uid,
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
          photoUrl: '',
          createdAt: DateTime.now(),
        ),
      );

      await auth.sendEmailVerification();
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final auth = _ref.read(authServiceProvider);
      final credential = await auth.signInWithGoogle();
      final uid = credential.user!.uid;
      final existing = await _ref.read(userRepositoryProvider).getProfile(uid);
      if (existing == null) {
        await _ref.read(userRepositoryProvider).createProfile(
              UserModel(
                uid: uid,
                fullName: credential.user?.displayName ?? 'New User',
                email: credential.user?.email,
                photoUrl: credential.user?.photoURL ?? '',
                createdAt: DateTime.now(),
              ),
            );
      }
    });
  }

  Future<void> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _ref.read(authServiceProvider).sendPasswordResetEmail(email);
    });
  }

  Future<void> signOut() async {
    final uid = _ref.read(authServiceProvider).currentUser?.uid;
    if (uid != null) {
      await _ref.read(userRepositoryProvider).setOnlineStatus(uid, false);
    }
    await _ref.read(authServiceProvider).signOut();
  }

  Future<void> deleteAccount() async {
    final uid = _ref.read(authServiceProvider).currentUser?.uid;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (uid != null) {
        await _ref.read(userRepositoryProvider).deleteProfile(uid);
      }
      await _ref.read(authServiceProvider).deleteAccount();
    });
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>(
  (ref) => AuthController(ref),
);
