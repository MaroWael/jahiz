import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jahiz/features/home/models/practice_session_record.dart';

class PracticeSessionService {
  factory PracticeSessionService() => _instance;

  PracticeSessionService._internal();

  static final PracticeSessionService _instance =
      PracticeSessionService._internal();

  Future<List<PracticeSessionRecord>> getCompletedSessions() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const <PracticeSessionRecord>[];
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('practiceSessions')
        .get();

    if (snapshot.docs.isEmpty) {
      return const <PracticeSessionRecord>[];
    }

    final sessions = <PracticeSessionRecord>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final scorePercent = _readScorePercent(data);
      if (scorePercent == null) {
        continue;
      }

      sessions.add(
        PracticeSessionRecord(
          scorePercent: scorePercent.clamp(0, 100).toDouble(),
          date: _readSessionDate(data),
        ),
      );
    }

    sessions.sort((a, b) {
      if (a.date == null && b.date == null) {
        return 0;
      }
      if (a.date == null) {
        return 1;
      }
      if (b.date == null) {
        return -1;
      }
      return b.date!.compareTo(a.date!);
    });

    return sessions;
  }

  double? _readScorePercent(Map<String, dynamic> data) {
    final direct = data['averageScorePercent'];
    if (direct is num) {
      return direct.toDouble();
    }

    final averageScore = data['averageScore'];
    if (averageScore is num) {
      return averageScore.toDouble() * 10;
    }

    return null;
  }

  DateTime? _readSessionDate(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      return createdAt.toDate();
    }

    final createdAtClient = data['createdAtClient'];
    if (createdAtClient is Timestamp) {
      return createdAtClient.toDate();
    }

    return null;
  }
}
