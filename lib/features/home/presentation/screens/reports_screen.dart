import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jahiz/features/home/models/reports_overview.dart';
import 'package:jahiz/features/home/models/weak_area.dart';
import 'package:jahiz/features/home/presentation/cubit/reports_cubit.dart';
import 'package:jahiz/features/home/presentation/cubit/reports_state.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const int _weakAreaPreviewCount = 3;

  late final ReportsCubit _reportsCubit;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _reportsCubit = ReportsCubit()..initialize();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _reportsCubit.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    await _reportsCubit.refresh();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 220) {
      _reportsCubit.loadMoreHistory();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Unknown date';
    }

    final local = date.toLocal();
    final month = _monthName(local.month);
    return '$month ${local.day}, ${local.year}';
  }

  String _monthName(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }

  void _toggleWeakArea(String topic) {
    _reportsCubit.toggleWeakArea(topic);
  }

  Widget _reveal({required int order, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + (order * 70)),
      curve: Curves.easeOutCubic,
      builder: (context, value, animatedChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: animatedChild,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildSurfaceCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15001A72),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHeroCard(ReportsOverview metrics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF0A6CFF), Color(0xFF17A3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_graph_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Practice Pulse',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  metrics.averageScorePercent == null
                      ? 'Complete your first session to unlock insights.'
                      : 'Average ${metrics.averageScorePercent!.toStringAsFixed(1)}% across ${metrics.sessionCount} sessions',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeakAreaCard(ReportsState state, WeakArea weakArea) {
    final isExpanded = state.expandedWeakAreaTopics.contains(weakArea.topic);
    final hasMore = weakArea.lowQuestions.length > _weakAreaPreviewCount;
    final visibleQuestions = isExpanded
        ? weakArea.lowQuestions
        : weakArea.lowQuestions.take(_weakAreaPreviewCount).toList();

    Widget questionTile(WeakQuestion question) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.quiz_outlined,
                size: 16,
                color: Color(0xFF3669E8),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                question.question,
                style: const TextStyle(height: 1.3),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${question.scorePercent.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFB3261E),
              ),
            ),
          ],
        ),
      );
    }

    return _buildSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  weakArea.topic,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFEF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${weakArea.averageScorePercent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Color(0xFFB3261E),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (visibleQuestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Questions below 50%',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: Column(
                children: visibleQuestions.map(questionTile).toList(),
              ),
            ),
            if (hasMore)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _toggleWeakArea(weakArea.topic),
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                  ),
                  label: Text(
                    isExpanded
                        ? 'Show less'
                        : 'Show more (${weakArea.lowQuestions.length - _weakAreaPreviewCount})',
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return _buildSurfaceCard(
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.insights_outlined,
              size: 30,
              color: Color(0xFF2D64E3),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No practice data yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start your first practice session to see your average score, history, and weak areas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.35),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/practice'),
              child: const Text('Start Your First Practice'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHistorySection(ReportsState state) {
    if (state.historySessions.isEmpty && state.isHistoryLoading) {
      return const <Widget>[
        SizedBox(height: 16),
        Center(child: CircularProgressIndicator()),
      ];
    }

    if (state.historySessions.isEmpty && state.historyError != null) {
      return <Widget>[
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Unable to load history. Please try again.'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _reportsCubit.loadMoreHistory(reset: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ];
    }

    if (state.historySessions.isEmpty) {
      return <Widget>[
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Text('No completed sessions yet.'),
        ),
      ];
    }

    final widgets = <Widget>[];
    for (final session in state.historySessions) {
      widgets.add(
        Container(
          key: ValueKey<String>(session.id),
          margin: const EdgeInsets.only(bottom: 10),
          child: _buildSurfaceCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.work_outline_rounded,
                            size: 16,
                            color: Color(0xFF3669E8),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              session.role,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(session.date),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${session.scorePercent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF1D4DC9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.isHistoryLoading) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (state.historyError != null) {
      widgets.add(
        Center(
          child: TextButton(
            onPressed: () => _reportsCubit.loadMoreHistory(),
            child: const Text('Retry loading more history'),
          ),
        ),
      );
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReportsCubit>.value(
      value: _reportsCubit,
      child: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          if (state.isLoadingMetrics && state.metrics == null) {
            return const Scaffold(
              backgroundColor: Color(0xFFF4F6FB),
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state.metricsError != null && state.metrics == null) {
            return Scaffold(
              backgroundColor: const Color(0xFFF4F6FB),
              appBar: AppBar(title: const Text('Reports')),
              body: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: const [
                    Text(
                      'Unable to load reports right now. Pull to refresh and try again.',
                    ),
                  ],
                ),
              ),
            );
          }

          final metrics =
              state.metrics ??
              const ReportsOverview(
                averageScorePercent: null,
                sessionCount: 0,
                weakAreas: [],
              );

          return Scaffold(
            backgroundColor: const Color(0xFFF4F6FB),
            appBar: AppBar(title: const Text('Reports')),
            body: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _reveal(order: 0, child: _buildHeroCard(metrics)),
                  const SizedBox(height: 16),
                  _reveal(
                    order: 1,
                    child: const Text(
                      'Performance Overview',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!metrics.hasData)
                    _reveal(order: 2, child: _buildEmptyState())
                  else if (metrics.averageScorePercent != null)
                    _reveal(
                      order: 2,
                      child: _buildSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Average Score',
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              child: Text(
                                key: ValueKey<String>(
                                  metrics.averageScorePercent!.toStringAsFixed(
                                    1,
                                  ),
                                ),
                                '${metrics.averageScorePercent!.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Across ${metrics.sessionCount} completed sessions',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _reveal(
                      order: 2,
                      child: _buildSurfaceCard(
                        child: const Text(
                          'Complete at least one practice session to see reports.',
                        ),
                      ),
                    ),
                  if (metrics.hasData) ...[
                    const SizedBox(height: 16),
                    _reveal(
                      order: 3,
                      child: const Text(
                        'Weak Areas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (metrics.weakAreas.isEmpty)
                      _reveal(
                        order: 4,
                        child: _buildSurfaceCard(
                          child: const Text('No weak areas detected'),
                        ),
                      )
                    else
                      ...metrics.weakAreas.asMap().entries.map(
                        (entry) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: _reveal(
                            order: 4 + entry.key,
                            child: _buildWeakAreaCard(state, entry.value),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _reveal(
                      order: 12,
                      child: const Text(
                        'History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._buildHistorySection(state).asMap().entries.map(
                      (entry) =>
                          _reveal(order: 13 + entry.key, child: entry.value),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
