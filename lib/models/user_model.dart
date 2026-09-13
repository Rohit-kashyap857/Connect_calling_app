import 'package:cloud_firestore/cloud_firestore.dart';

enum RelationshipGoal { longTerm, casual, friendship, notSure }

enum MembershipTier { free, luxury }

enum UserRole { user, admin }

enum VendorStatus { none, pending, approved, rejected }

class UserModel {
  final String uid;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String photoUrl;
  final bool isOnline;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.fullName,
    this.email,
    this.phoneNumber,
    required this.photoUrl,
    this.isOnline = false,
    required this.createdAt,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      photoUrl: map['photoUrl'] as String? ?? '',
      isOnline: map['isOnline'] as bool? ?? false,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? fullName,
    List<String>? interests,
    String? photoUrl,
    List<String>? galleryUrls,
    bool? isOnline,
    bool? hideProfile,
    bool? privacyMode,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt,
    );
  }
}
