class PracticeSessionRecord {
  const PracticeSessionRecord({
    required this.id,
    required this.role,
    required this.scorePercent,
    required this.date,
  });

  final String id;
  final String role;
  final double scorePercent;
  final DateTime? date;
}
