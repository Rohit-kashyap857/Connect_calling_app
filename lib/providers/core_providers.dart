import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/call_repository.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';
import '../services/ice_server_service.dart';
import '../services/notification_service.dart';

final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final iceServerServiceProvider =
    Provider<IceServerService>((ref) => IceServerService());
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());
final userRepositoryProvider =
    Provider<UserRepository>((ref) => UserRepository());
final callRepositoryProvider =
    Provider<CallRepository>((ref) => CallRepository());
