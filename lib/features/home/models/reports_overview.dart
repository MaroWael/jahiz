import 'package:jahiz/features/home/models/practice_session_record.dart';

class ReportsOverview {
  const ReportsOverview({
    required this.averageScorePercent,
    required this.sessionCount,
    required this.sessions,
  });

  final double? averageScorePercent;
  final int sessionCount;
  final List<PracticeSessionRecord> sessions;
}
