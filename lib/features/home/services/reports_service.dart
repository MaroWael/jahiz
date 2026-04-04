import 'package:jahiz/features/home/models/reports_overview.dart';
import 'package:jahiz/features/home/services/practice_session_service.dart';

class ReportsService {
  factory ReportsService({PracticeSessionService? practiceSessionService}) {
    if (practiceSessionService != null) {
      _instance._practiceSessionService = practiceSessionService;
    }
    return _instance;
  }

  ReportsService._internal();

  static final ReportsService _instance = ReportsService._internal();

  PracticeSessionService _practiceSessionService = PracticeSessionService();

  Future<ReportsOverview> getReportsOverview() async {
    final sessions = await _practiceSessionService.getCompletedSessions();
    if (sessions.isEmpty) {
      return const ReportsOverview(
        averageScorePercent: null,
        sessionCount: 0,
        sessions: [],
      );
    }

    final totalScorePercent = sessions.fold<double>(
      0,
      (sum, session) => sum + session.scorePercent,
    );

    return ReportsOverview(
      averageScorePercent: totalScorePercent / sessions.length,
      sessionCount: sessions.length,
      sessions: sessions,
    );
  }
}
