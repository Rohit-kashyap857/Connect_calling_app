import 'package:cloud_firestore/cloud_firestore.dart';

enum CallType { voice, video }

enum CallStatus { ringing, ongoing, ended, missed, declined, connecting }

class CallModel {
  final String id;
  final String callerId;
  final String calleeId;
  final String chatId;
  final CallType type;
  final CallStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationSeconds;

  const CallModel({
    required this.id,
    required this.callerId,
    required this.calleeId,
    required this.chatId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.durationSeconds = 0,
  });

  factory CallModel.fromMap(String id, Map<String, dynamic> map) {
    return CallModel(
      id: id,
      callerId: map['callerId'] as String? ?? '',
      calleeId: map['calleeId'] as String? ?? '',
      chatId: map['chatId'] as String? ?? '',
      type: CallType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'voice'),
        orElse: () => CallType.voice,
      ),
      status: CallStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'ended'),
        orElse: () => CallStatus.ended,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (map['startedAt'] as Timestamp?)?.toDate(),
      endedAt: (map['endedAt'] as Timestamp?)?.toDate(),
      durationSeconds: map['durationSeconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'callerId': callerId,
      'calleeId': calleeId,
      'chatId': chatId,
      'type': type.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'durationSeconds': durationSeconds,
    };
  }

  String otherUid(String myUid) => callerId == myUid ? calleeId : callerId;
  bool isCaller(String myUid) => callerId == myUid;
}
