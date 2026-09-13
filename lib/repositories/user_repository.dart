import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestorePaths.users);

  Future<void> createProfile(UserModel user) {
    return _users.doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();

    if (!doc.exists) return null;

    return UserModel.fromMap(
      doc.id,
      doc.data()!,
    );
  }

  Stream<UserModel?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;

      return UserModel.fromMap(
        doc.id,
        doc.data()!,
      );
    });
  }

  Future<void> updateProfile(
      String uid,
      Map<String, dynamic> data,
      ) {
    return _users.doc(uid).update(data);
  }

  Stream<List<UserModel>> watchAllUsers(String currentUid) {
    return _users.snapshots().map(
          (snap) {
        return snap.docs
            .where((doc) => doc.id != currentUid)
            .map(
              (doc) => UserModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
            .toList();
      },
    );
  }
  Future<List<UserModel>> searchUsers(
      String currentUid,
      String query,
      ) async {
    final search = query.trim();

    if (search.isEmpty) {
      return [];
    }
    final normalizedSearch = search.replaceAll(
      RegExp(r'[\s\-\(\)]'),
      '',
    );

    final snapshot = await _users.get();

    return snapshot.docs
        .where((doc) => doc.id != currentUid)
        .map(
          (doc) => UserModel.fromMap(
        doc.id,
        doc.data(),
      ),
    )
        .where((user) {
      final phone = user.phoneNumber?.replaceAll(
        RegExp(r'[\s\-\(\)]'),
        '',
      );

      if (phone == null || phone.isEmpty) {
        return false;
      }

      return phone.contains(normalizedSearch);
    })
        .toList();
  }
  // ---------------------------------------------------------------------------
  // CONTACTS
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _contacts(
      String uid,
      ) {
    return _users
        .doc(uid)
        .collection('contacts');
  }

  /// Add another user to my contacts.
  Future<void> addContact({
    required String myUid,
    required String contactUid,
  }) async {
    if (myUid == contactUid) {
      return;
    }

    await _contacts(myUid).doc(contactUid).set({
      'uid': contactUid,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove another user from my contacts.
  Future<void> removeContact({
    required String myUid,
    required String contactUid,
  }) async {
    await _contacts(myUid)
        .doc(contactUid)
        .delete();
  }

  /// Check whether a user is already in my contacts.
  Future<bool> isContact({
    required String myUid,
    required String contactUid,
  }) async {
    final doc = await _contacts(myUid)
        .doc(contactUid)
        .get();

    return doc.exists;
  }

  /// Watch all contacts.
  ///
  /// We first watch the contact IDs and then load their profiles.
  Stream<List<UserModel>> watchContacts(
      String myUid,
      ) async* {
    await for (final snapshot in _contacts(myUid)
        .orderBy('addedAt', descending: true)
        .snapshots()) {
      if (snapshot.docs.isEmpty) {
        yield [];
        continue;
      }

      final users = <UserModel>[];

      for (final contactDoc in snapshot.docs) {
        final uid = contactDoc.id;

        final userDoc = await _users.doc(uid).get();

        if (!userDoc.exists) {
          continue;
        }

        users.add(
          UserModel.fromMap(
            userDoc.id,
            userDoc.data()!,
          ),
        );
      }

      yield users;
    }
  }

  // ---------------------------------------------------------------------------
  // ONLINE STATUS
  // ---------------------------------------------------------------------------

  Future<void> setOnlineStatus(
      String uid,
      bool isOnline,
      ) {
    return _users.doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': Timestamp.now(),
    });
  }

  // ---------------------------------------------------------------------------
  // LOCATION
  // ---------------------------------------------------------------------------

  Future<void> updateLocation(
      String uid, {
        required double latitude,
        required double longitude,
        String? city,
      }) {
    final data = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    };

    if (city != null) {
      data['city'] = city;
    }

    return _users.doc(uid).update(data);
  }

  Future<void> updateDistancePreference(
      String uid,
      double km,
      ) {
    return _users.doc(uid).update({
      'distancePreferenceKm': km,
    });
  }

  // ---------------------------------------------------------------------------
  // FCM
  // ---------------------------------------------------------------------------

  Future<void> addFcmToken(
      String uid,
      String token,
      ) {
    return _users.doc(uid).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }

  Future<void> removeFcmToken(
      String uid,
      String token,
      ) {
    return _users.doc(uid).update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
  }

  // ---------------------------------------------------------------------------
  // PRIVACY
  // ---------------------------------------------------------------------------

  Future<void> updatePrivacySettings(
      String uid, {
        bool? hideProfile,
        bool? anonymousGifting,
        bool? giftOnlyMode,
        bool? privacyMode,
      }) {
    final data = <String, dynamic>{};

    if (hideProfile != null) {
      data['hideProfile'] = hideProfile;
    }

    if (anonymousGifting != null) {
      data['anonymousGifting'] = anonymousGifting;
    }

    if (giftOnlyMode != null) {
      data['giftOnlyMode'] = giftOnlyMode;
    }

    if (privacyMode != null) {
      data['privacyMode'] = privacyMode;
    }

    return _users.doc(uid).update(data);
  }

  // ---------------------------------------------------------------------------
  // DELETE PROFILE
  // ---------------------------------------------------------------------------

  Future<void> deleteProfile(String uid) {
    return _users.doc(uid).delete();
  }

  // ---------------------------------------------------------------------------
  // VENDOR
  // ---------------------------------------------------------------------------

  Future<void> applyAsVendor(
      String uid, {
        required String businessName,
        required String businessDescription,
        String? businessLogoUrl,
      }) {
    return _users.doc(uid).update({
      'vendorStatus': VendorStatus.approved.name,
      'businessName': businessName,
      'businessDescription': businessDescription,
      'businessLogoUrl': businessLogoUrl,
    });
  }

  Future<void> updateVendorProfile(
      String uid, {
        String? businessName,
        String? businessDescription,
        String? businessLogoUrl,
      }) {
    final data = <String, dynamic>{};

    if (businessName != null) {
      data['businessName'] = businessName;
    }

    if (businessDescription != null) {
      data['businessDescription'] = businessDescription;
    }

    if (businessLogoUrl != null) {
      data['businessLogoUrl'] = businessLogoUrl;
    }

    return _users.doc(uid).update(data);
  }
}