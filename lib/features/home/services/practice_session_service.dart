import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jahiz/features/home/models/practice_session_record.dart';
import 'package:jahiz/features/home/models/session_history_page.dart';
import 'package:jahiz/features/home/models/weak_area.dart';

class PracticeSessionService {
  factory PracticeSessionService() => _instance;

  PracticeSessionService._internal();

  static final PracticeSessionService _instance =
      PracticeSessionService._internal();

  Future<List<PracticeSessionRecord>> getCompletedSessions() async {
    final snapshot = await _loadSessionsSnapshot();

    if (snapshot == null || snapshot.docs.isEmpty) {
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
          id: doc.id,
          role: _readSessionJob(data),
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

  Future<SessionHistoryPage> getCompletedSessionsPage({
    int limit = 20,
    DateTime? startAfterDate,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const SessionHistoryPage(
        sessions: <PracticeSessionRecord>[],
        nextPageCursor: null,
        hasMore: false,
      );
    }

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('practiceSessions')
        .orderBy('createdAtClient', descending: true)
        .limit(limit);

    if (startAfterDate != null) {
      query = query.startAfter([Timestamp.fromDate(startAfterDate.toUtc())]);
    }

    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) {
      return const SessionHistoryPage(
        sessions: <PracticeSessionRecord>[],
        nextPageCursor: null,
        hasMore: false,
      );
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
          id: doc.id,
          role: _readSessionJob(data),
          scorePercent: scorePercent.clamp(0, 100).toDouble(),
          date: _readSessionDate(data),
        ),
      );
    }

    final lastDocData = snapshot.docs.last.data();
    final nextCursor = _readSessionDate(lastDocData);
    final hasMore = snapshot.docs.length == limit && nextCursor != null;

    return SessionHistoryPage(
      sessions: sessions,
      nextPageCursor: hasMore ? nextCursor : null,
      hasMore: hasMore,
    );
  }

  Future<List<WeakArea>> getWeakAreas({double thresholdPercent = 50}) async {
    final snapshot = await _loadSessionsSnapshot();
    if (snapshot == null || snapshot.docs.isEmpty) {
      return const <WeakArea>[];
    }

    final lowQuestionsByJob = <String, List<WeakQuestion>>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final job = _readSessionJob(data);
      final lowQuestions = _readLowQuestions(
        data,
        thresholdPercent: thresholdPercent,
      );

      if (lowQuestions.isNotEmpty) {
        lowQuestionsByJob
            .putIfAbsent(job, () => <WeakQuestion>[])
            .addAll(lowQuestions);
        continue;
      }

      final sessionScore = _readScorePercent(data);
      if (sessionScore == null || sessionScore >= thresholdPercent) {
        continue;
      }

      lowQuestionsByJob
          .putIfAbsent(job, () => <WeakQuestion>[])
          .add(
            WeakQuestion(
              question:
                  'Session average score below ${thresholdPercent.toInt()}%',
              scorePercent: sessionScore.clamp(0, 100).toDouble(),
            ),
          );
    }

    if (lowQuestionsByJob.isEmpty) {
      return const <WeakArea>[];
    }

    final weakAreas = <WeakArea>[];
    lowQuestionsByJob.forEach((job, lowQuestions) {
      if (lowQuestions.isEmpty) {
        return;
      }

      final total = lowQuestions.fold<double>(
        0,
        (sum, item) => sum + item.scorePercent,
      );

      final orderedQuestions = List<WeakQuestion>.from(lowQuestions)
        ..sort((a, b) => a.scorePercent.compareTo(b.scorePercent));

      weakAreas.add(
        WeakArea(
          topic: job,
          averageScorePercent: total / lowQuestions.length,
          lowQuestions: orderedQuestions,
        ),
      );
    });

    weakAreas.sort(
      (a, b) => a.averageScorePercent.compareTo(b.averageScorePercent),
    );
    return weakAreas;
  }

  Future<QuerySnapshot<Map<String, dynamic>>?> _loadSessionsSnapshot() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('practiceSessions')
        .get();
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

  List<WeakQuestion> _readLowQuestions(
    Map<String, dynamic> data, {
    required double thresholdPercent,
  }) {
    final fromStoredWeakQuestions = _readLowQuestionsFromStoredField(
      data,
      thresholdPercent: thresholdPercent,
    );
    if (fromStoredWeakQuestions.isNotEmpty) {
      return fromStoredWeakQuestions;
    }

    final questionResults = data['questionResults'];
    if (questionResults is! List) {
      return const <WeakQuestion>[];
    }

    final lowQuestions = <WeakQuestion>[];
    for (final item in questionResults) {
      if (item is! Map) {
        continue;
      }

      final question = (item['question'] ?? '').toString().trim();
      if (question.isEmpty) {
        continue;
      }

      final scorePercent = _readQuestionScorePercent(item);
      if (scorePercent == null || scorePercent >= thresholdPercent) {
        continue;
      }

      lowQuestions.add(
        WeakQuestion(
          question: question,
          scorePercent: scorePercent.clamp(0, 100).toDouble(),
        ),
      );
    }

    return lowQuestions;
  }

  List<WeakQuestion> _readLowQuestionsFromStoredField(
    Map<String, dynamic> data, {
    required double thresholdPercent,
  }) {
    final stored = data['weakQuestions'];
    if (stored is! List) {
      return const <WeakQuestion>[];
    }

    final lowQuestions = <WeakQuestion>[];
    for (final item in stored) {
      if (item is! Map) {
        continue;
      }

      final question = (item['question'] ?? '').toString().trim();
      if (question.isEmpty) {
        continue;
      }

      final rawScore = item['scorePercent'];
      if (rawScore is! num) {
        continue;
      }

      final scorePercent = rawScore.toDouble();
      if (scorePercent >= thresholdPercent) {
        continue;
      }

      lowQuestions.add(
        WeakQuestion(
          question: question,
          scorePercent: scorePercent.clamp(0, 100).toDouble(),
        ),
      );
    }

    return lowQuestions;
  }

  double? _readQuestionScorePercent(Map item) {
    final direct = item['scorePercent'];
    if (direct is num) {
      return direct.toDouble();
    }

    final score = item['score'];
    if (score is num) {
      return (score.toDouble() * 10).clamp(0, 100).toDouble();
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

  String _readSessionJob(Map<String, dynamic> data) {
    final practiceJob = (data['practiceJob'] ?? '').toString().trim();
    if (practiceJob.isNotEmpty) {
      return practiceJob;
    }

    final role = (data['role'] ?? '').toString().trim();
    if (role.isNotEmpty) {
      return role;
    }

    final rawTopics = data['techStack'];
    if (rawTopics is List && rawTopics.isNotEmpty) {
      final firstTopic = rawTopics.first.toString().trim();
      if (firstTopic.isNotEmpty) {
        return firstTopic;
      }
    }

    return 'General';
  }
}
