import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/call_model.dart';

class CallRepository {
  CallRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _calls =>
      _db.collection(FirestorePaths.calls);

  DocumentReference<Map<String, dynamic>> callDoc(String callId) =>
      _calls.doc(callId);

  Future<String> createCall({
    required String callerId,
    required String calleeId,
    required String chatId,
    required CallType type,
  }) async {
    final ref = _calls.doc();

    await ref.set(
      CallModel(
        id: ref.id,
        callerId: callerId,
        calleeId: calleeId,
        chatId: chatId,
        type: type,
        status: CallStatus.ringing,
        createdAt: DateTime.now(),
      ).toMap(),
    );

    return ref.id;
  }

  Future<void> setOffer(
      String callId,
      Map<String, dynamic> offer,
      ) {
    return callDoc(callId).update({
      'offer': offer,
    });
  }

  Future<void> setAnswer(
      String callId,
      Map<String, dynamic> answer,
      ) {
    return callDoc(callId).update({
      'answer': answer,
      'status': CallStatus.ongoing.name,
      'startedAt': Timestamp.now(),
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchCallDoc(
      String callId,
      ) {
    return callDoc(callId).snapshots();
  }

  Future<void> addCandidate({
    required String callId,
    required bool isCaller,
    required Map<String, dynamic> candidate,
  }) {
    final subcollection =
    isCaller ? 'callerCandidates' : 'calleeCandidates';

    return callDoc(callId)
        .collection(subcollection)
        .add(candidate);
  }

  Stream<List<Map<String, dynamic>>> watchRemoteCandidates({
    required String callId,
    required bool isCaller,
  }) {
    final subcollection =
    isCaller ? 'calleeCandidates' : 'callerCandidates';

    return callDoc(callId)
        .collection(subcollection)
        .snapshots()
        .map(
          (snap) => snap.docChanges
          .where(
            (change) =>
        change.type == DocumentChangeType.added,
      )
          .map(
            (change) => change.doc.data()!,
      )
          .toList(),
    );
  }

  Future<void> updateStatus(
      String callId,
      CallStatus status,
      ) {
    final data = <String, dynamic>{
      'status': status.name,
    };

    if (status == CallStatus.ended ||
        status == CallStatus.declined ||
        status == CallStatus.missed) {
      data['endedAt'] = Timestamp.now();
    }

    return callDoc(callId).update(data);
  }

  Future<void> setDuration(
      String callId,
      int seconds,
      ) {
    return callDoc(callId).update({
      'durationSeconds': seconds,
    });
  }

  Stream<CallModel?> watchIncomingCall(String myUid) {
    return _calls
        .where(
      'calleeId',
      isEqualTo: myUid,
    )
        .where(
      'status',
      isEqualTo: CallStatus.ringing.name,
    )
        .limit(1)
        .snapshots()
        .map(
          (snap) => snap.docs.isEmpty
          ? null
          : CallModel.fromMap(
        snap.docs.first.id,
        snap.docs.first.data(),
      ),
    );
  }

  Stream<List<CallModel>> watchCallHistory(String myUid) {
    final controller =
    StreamController<List<CallModel>>();

    final callerCalls =
    <String, CallModel>{};

    final calleeCalls =
    <String, CallModel>{};

    bool callerLoaded = false;
    bool calleeLoaded = false;

    void emitHistory() {
      if (!callerLoaded || !calleeLoaded) {
        return;
      }

      final allCalls = <String, CallModel>{};

      allCalls.addAll(callerCalls);
      allCalls.addAll(calleeCalls);

      final history = allCalls.values.toList();

      history.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      controller.add(
        history.take(50).toList(),
      );
    }

    final callerSubscription = _calls
        .where(
      'callerId',
      isEqualTo: myUid,
    )
        .snapshots()
        .listen(
          (snapshot) {
        callerCalls.clear();

        for (final doc in snapshot.docs) {
          callerCalls[doc.id] = CallModel.fromMap(
            doc.id,
            doc.data(),
          );
        }

        callerLoaded = true;
        emitHistory();
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!controller.isClosed) {
          controller.addError(
            error,
            stackTrace,
          );
        }
      },
    );

    final calleeSubscription = _calls
        .where(
      'calleeId',
      isEqualTo: myUid,
    )
        .snapshots()
        .listen(
          (snapshot) {
        calleeCalls.clear();

        for (final doc in snapshot.docs) {
          calleeCalls[doc.id] = CallModel.fromMap(
            doc.id,
            doc.data(),
          );
        }

        calleeLoaded = true;
        emitHistory();
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!controller.isClosed) {
          controller.addError(
            error,
            stackTrace,
          );
        }
      },
    );

    controller.onCancel = () async {
      await callerSubscription.cancel();
      await calleeSubscription.cancel();
    };

    return controller.stream;
  }

  Future<void> deleteCall(String callId) async {
    await cleanupCandidates(callId);

    await callDoc(callId).delete();
  }

  Future<void> deleteUserCallHistory({
    required String myUid,
    required String otherUid,
  }) async {
    final myCallsSnapshot = await _calls
        .where(
      'callerId',
      isEqualTo: myUid,
    )
        .where(
      'calleeId',
      isEqualTo: otherUid,
    )
        .get();

    final otherCallsSnapshot = await _calls
        .where(
      'callerId',
      isEqualTo: otherUid,
    )
        .where(
      'calleeId',
      isEqualTo: myUid,
    )
        .get();

    final docsById =
    <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

    for (final doc in myCallsSnapshot.docs) {
      docsById[doc.id] = doc;
    }

    for (final doc in otherCallsSnapshot.docs) {
      docsById[doc.id] = doc;
    }

    final docs = docsById.values.toList();

    for (var i = 0; i < docs.length; i += 450) {
      final batch = _db.batch();

      final end = (i + 450 < docs.length)
          ? i + 450
          : docs.length;

      for (final doc in docs.sublist(i, end)) {
        for (final subcollection in [
          'callerCandidates',
          'calleeCandidates',
        ]) {
          final candidates = await doc.reference
              .collection(subcollection)
              .get();

          for (final candidate in candidates.docs) {
            batch.delete(candidate.reference);
          }
        }

        batch.delete(doc.reference);
      }

      await batch.commit();
    }
  }

  Future<void> cleanupCandidates(String callId) async {
    for (final subcollection in [
      'callerCandidates',
      'calleeCandidates',
    ]) {
      final docs = await callDoc(callId)
          .collection(subcollection)
          .get();

      if (docs.docs.isEmpty) {
        continue;
      }

      final batch = _db.batch();

      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    }
  }
}