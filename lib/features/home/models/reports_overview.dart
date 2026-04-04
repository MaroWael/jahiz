import 'package:jahiz/features/home/models/weak_area.dart';

class ReportsOverview {
  const ReportsOverview({
    required this.averageScorePercent,
    required this.sessionCount,
    required this.weakAreas,
  });

  final double? averageScorePercent;
  final int sessionCount;
  final List<WeakArea> weakAreas;

  bool get hasData => sessionCount > 0;
}
