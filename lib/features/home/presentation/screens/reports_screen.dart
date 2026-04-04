import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<_ReportsMetrics> _metricsFuture;

  @override
  void initState() {
    super.initState();
    _metricsFuture = _loadMetrics();
  }

  Future<void> _refresh() async {
    setState(() {
      _metricsFuture = _loadMetrics();
    });
    await _metricsFuture;
  }

  Future<_ReportsMetrics> _loadMetrics() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const _ReportsMetrics(averageScorePercent: null, sessionCount: 0);
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('practiceSessions')
        .get();

    if (snapshot.docs.isEmpty) {
      return const _ReportsMetrics(averageScorePercent: null, sessionCount: 0);
    }

    var totalScorePercent = 0.0;
    var countedSessions = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final scorePercent = _readScorePercent(data);
      if (scorePercent == null) {
        continue;
      }

      totalScorePercent += scorePercent.clamp(0, 100).toDouble();
      countedSessions += 1;
    }

    if (countedSessions == 0) {
      return const _ReportsMetrics(averageScorePercent: null, sessionCount: 0);
    }

    return _ReportsMetrics(
      averageScorePercent: totalScorePercent / countedSessions,
      sessionCount: countedSessions,
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(title: const Text('Reports')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_ReportsMetrics>(
          future: _metricsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: const [
                  Text(
                    'Unable to load reports right now. Pull to refresh and try again.',
                  ),
                ],
              );
            }

            final metrics =
                snapshot.data ??
                const _ReportsMetrics(
                  averageScorePercent: null,
                  sessionCount: 0,
                );

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Performance Overview',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                if (metrics.averageScorePercent != null)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
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
                        Text(
                          '${metrics.averageScorePercent!.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Across ${metrics.sessionCount} completed sessions',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'Complete at least one practice session to see reports.',
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReportsMetrics {
  const _ReportsMetrics({
    required this.averageScorePercent,
    required this.sessionCount,
  });

  final double? averageScorePercent;
  final int sessionCount;
}
