import 'package:jahiz/features/home/models/practice_session_record.dart';
import 'package:jahiz/features/home/models/session_summary.dart';
import 'package:jahiz/features/home/services/practice_session_service.dart';

class SessionSummaryService {
  factory SessionSummaryService({
    PracticeSessionService? practiceSessionService,
  }) {
    if (practiceSessionService != null) {
      _instance._practiceSessionService = practiceSessionService;
    }
    return _instance;
  }

  SessionSummaryService._internal();

  static final SessionSummaryService _instance =
      SessionSummaryService._internal();

  PracticeSessionService _practiceSessionService = PracticeSessionService();

  Future<SessionSummary?> getLastSessionSummary() async {
    final sessions = await _practiceSessionService.getCompletedSessions();
    if (sessions.isEmpty) {
      return null;
    }

    final latestSession = sessions.first;
    final streak = _calculateStreak(sessions);

    return SessionSummary(
      score: latestSession.scorePercent.round(),
      streak: streak,
    );
  }

  int _calculateStreak(List<PracticeSessionRecord> sessions) {
    final uniqueDays =
        sessions
            .map((session) => session.date)
            .whereType<DateTime>()
            .map(_startOfDay)
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    if (uniqueDays.isEmpty) {
      return 0;
    }

    var streak = 1;
    for (var i = 0; i < uniqueDays.length - 1; i++) {
      final difference = uniqueDays[i].difference(uniqueDays[i + 1]).inDays;
      if (difference == 1) {
        streak += 1;
      } else {
        break;
      }
    }
    return streak;
  }

  DateTime _startOfDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
