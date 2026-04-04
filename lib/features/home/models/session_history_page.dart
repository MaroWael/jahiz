import 'package:jahiz/features/home/models/practice_session_record.dart';

class SessionHistoryPage {
  const SessionHistoryPage({
    required this.sessions,
    required this.nextPageCursor,
    required this.hasMore,
  });

  final List<PracticeSessionRecord> sessions;
  final DateTime? nextPageCursor;
  final bool hasMore;
}
