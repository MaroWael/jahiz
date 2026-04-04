import 'package:jahiz/features/home/models/practice_session_record.dart';
import 'package:jahiz/features/home/models/reports_overview.dart';

const _unsetObject = Object();
const _unsetDateTime = Object();
const _unsetMetrics = Object();

class ReportsState {
  const ReportsState({
    this.isLoadingMetrics = false,
    this.metrics,
    this.metricsError,
    this.historySessions = const <PracticeSessionRecord>[],
    this.expandedWeakAreaTopics = const <String>{},
    this.nextHistoryCursor,
    this.isHistoryLoading = false,
    this.hasMoreHistory = true,
    this.historyError,
  });

  final bool isLoadingMetrics;
  final ReportsOverview? metrics;
  final Object? metricsError;
  final List<PracticeSessionRecord> historySessions;
  final Set<String> expandedWeakAreaTopics;
  final DateTime? nextHistoryCursor;
  final bool isHistoryLoading;
  final bool hasMoreHistory;
  final Object? historyError;

  ReportsState copyWith({
    bool? isLoadingMetrics,
    Object? metrics = _unsetMetrics,
    Object? metricsError = _unsetObject,
    List<PracticeSessionRecord>? historySessions,
    Set<String>? expandedWeakAreaTopics,
    Object? nextHistoryCursor = _unsetDateTime,
    bool? isHistoryLoading,
    bool? hasMoreHistory,
    Object? historyError = _unsetObject,
  }) {
    return ReportsState(
      isLoadingMetrics: isLoadingMetrics ?? this.isLoadingMetrics,
      metrics: metrics == _unsetMetrics
          ? this.metrics
          : metrics as ReportsOverview?,
      metricsError: metricsError == _unsetObject
          ? this.metricsError
          : metricsError,
      historySessions: historySessions ?? this.historySessions,
      expandedWeakAreaTopics:
          expandedWeakAreaTopics ?? this.expandedWeakAreaTopics,
      nextHistoryCursor: nextHistoryCursor == _unsetDateTime
          ? this.nextHistoryCursor
          : nextHistoryCursor as DateTime?,
      isHistoryLoading: isHistoryLoading ?? this.isHistoryLoading,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      historyError: historyError == _unsetObject
          ? this.historyError
          : historyError,
    );
  }
}
