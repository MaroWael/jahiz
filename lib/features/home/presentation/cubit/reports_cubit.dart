import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jahiz/features/home/models/practice_session_record.dart';
import 'package:jahiz/features/home/presentation/cubit/reports_state.dart';
import 'package:jahiz/features/home/services/reports_service.dart';

class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit({ReportsService? reportsService})
    : _reportsService = reportsService ?? ReportsService(),
      super(const ReportsState());

  static const int historyPageSize = 20;

  final ReportsService _reportsService;

  Future<void> initialize() async {
    await Future.wait<void>([loadMetrics(), loadMoreHistory(reset: true)]);
  }

  Future<void> refresh() async {
    await Future.wait<void>([loadMetrics(), loadMoreHistory(reset: true)]);
  }

  Future<void> loadMetrics() async {
    emit(state.copyWith(isLoadingMetrics: true, metricsError: null));

    try {
      final metrics = await _reportsService.getReportsOverview();
      emit(
        state.copyWith(
          isLoadingMetrics: false,
          metrics: metrics,
          metricsError: null,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoadingMetrics: false, metricsError: error));
    }
  }

  Future<void> loadMoreHistory({bool reset = false}) async {
    if (state.isHistoryLoading) {
      return;
    }
    if (!reset && !state.hasMoreHistory) {
      return;
    }

    if (reset) {
      emit(
        state.copyWith(
          isHistoryLoading: true,
          historyError: null,
          historySessions: <PracticeSessionRecord>[],
          nextHistoryCursor: null,
          hasMoreHistory: true,
        ),
      );
    } else {
      emit(state.copyWith(isHistoryLoading: true, historyError: null));
    }

    try {
      final page = await _reportsService.getHistoryPage(
        limit: historyPageSize,
        startAfterDate: reset ? null : state.nextHistoryCursor,
      );

      final sessions = <PracticeSessionRecord>[...state.historySessions];
      final existingIds = sessions.map((session) => session.id).toSet();

      for (final session in page.sessions) {
        if (!existingIds.contains(session.id)) {
          sessions.add(session);
          existingIds.add(session.id);
        }
      }

      emit(
        state.copyWith(
          historySessions: sessions,
          nextHistoryCursor: page.nextPageCursor,
          hasMoreHistory: page.hasMore,
          isHistoryLoading: false,
          historyError: null,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isHistoryLoading: false, historyError: error));
    }
  }

  void toggleWeakArea(String topic) {
    final updated = Set<String>.from(state.expandedWeakAreaTopics);
    if (updated.contains(topic)) {
      updated.remove(topic);
    } else {
      updated.add(topic);
    }

    emit(state.copyWith(expandedWeakAreaTopics: updated));
  }
}
