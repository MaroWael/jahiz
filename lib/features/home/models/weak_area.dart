class WeakQuestion {
  const WeakQuestion({required this.question, required this.scorePercent});

  final String question;
  final double scorePercent;
}

class WeakArea {
  const WeakArea({
    required this.topic,
    required this.averageScorePercent,
    this.lowQuestions = const <WeakQuestion>[],
  });

  final String topic;
  final double averageScorePercent;
  final List<WeakQuestion> lowQuestions;
}
