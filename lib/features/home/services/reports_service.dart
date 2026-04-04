import 'package:jahiz/features/home/models/reports_overview.dart';
import 'package:jahiz/features/home/models/session_history_page.dart';
import 'package:jahiz/features/home/services/practice_session_service.dart';

class ReportsService {
  factory ReportsService() => _instance;

  ReportsService._internal();

  static final ReportsService _instance = ReportsService._internal();

  final PracticeSessionService _practiceSessionService =
      PracticeSessionService();

  Future<ReportsOverview> getReportsOverview() async {
    final sessions = await _practiceSessionService.getCompletedSessions();
    final weakAreas = await _practiceSessionService.getWeakAreas();

    if (sessions.isEmpty) {
      return ReportsOverview(
        averageScorePercent: null,
        sessionCount: 0,
        weakAreas: weakAreas,
      );
    }

    final totalScorePercent = sessions.fold<double>(
      0,
      (sum, session) => sum + session.scorePercent,
    );

    return ReportsOverview(
      averageScorePercent: totalScorePercent / sessions.length,
      sessionCount: sessions.length,
      weakAreas: weakAreas,
    );
  }

  Future<SessionHistoryPage> getHistoryPage({
    int limit = 20,
    DateTime? startAfterDate,
  }) {
    return _practiceSessionService.getCompletedSessionsPage(
      limit: limit,
      startAfterDate: startAfterDate,
    );
  }
}
