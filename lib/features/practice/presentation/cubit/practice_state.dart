import 'package:jahiz/features/home/models/home_user.dart';
import 'package:jahiz/features/practice/models/practice_evaluation.dart';

class PracticeState {
  const PracticeState({
    this.isLoadingQuestions = false,
    this.isSubmitting = false,
    this.isSessionSubmitting = false,
    this.isSessionSubmitted = false,
    this.isTimeout = false,
    this.errorMessage,
    this.validationError,
    this.user,
    this.sessionRole,
    this.shouldShowPaywall = false,
    this.paywallFeatureName,
    this.paywallMessage,
    this.questions = const <String>[],
    this.currentIndex = 0,
    this.answers = const <int, String>{},
    this.evaluations = const <int, PracticeEvaluation>{},
  });

  final bool isLoadingQuestions;
  final bool isSubmitting;
  final bool isSessionSubmitting;
  final bool isSessionSubmitted;
  final bool isTimeout;
  final String? errorMessage;
  final String? validationError;
  final HomeUser? user;
  final String? sessionRole;
  final bool shouldShowPaywall;
  final String? paywallFeatureName;
  final String? paywallMessage;
  final List<String> questions;
  final int currentIndex;
  final Map<int, String> answers;
  final Map<int, PracticeEvaluation> evaluations;

  bool get hasQuestions => questions.isNotEmpty;

  String get currentQuestion => hasQuestions ? questions[currentIndex] : '';

  String get currentAnswer => answers[currentIndex] ?? '';

  PracticeEvaluation? get currentEvaluation => evaluations[currentIndex];

  int get submittedAnswersCount => evaluations.length;

  bool get isCurrentSubmitted => currentEvaluation != null;

  bool get canSubmitSession =>
      hasQuestions && submittedAnswersCount == questions.length;

  double get averageScore {
    if (evaluations.isEmpty) {
      return 0;
    }

    final total = evaluations.values
        .map((evaluation) => evaluation.score)
        .fold<double>(0, (sum, score) => sum + score);

    return total / evaluations.length;
  }

  List<double> get scoreByQuestion {
    final scores = <double>[];
    for (var index = 0; index < questions.length; index++) {
      scores.add(evaluations[index]?.score ?? 0);
    }
    return scores;
  }

  PracticeState copyWith({
    bool? isLoadingQuestions,
    bool? isSubmitting,
    bool? isSessionSubmitting,
    bool? isSessionSubmitted,
    bool? isTimeout,
    String? errorMessage,
    String? validationError,
    HomeUser? user,
    String? sessionRole,
    bool? shouldShowPaywall,
    String? paywallFeatureName,
    String? paywallMessage,
    List<String>? questions,
    int? currentIndex,
    Map<int, String>? answers,
    Map<int, PracticeEvaluation>? evaluations,
    bool clearError = false,
    bool clearValidationError = false,
    bool clearPaywallRequest = false,
  }) {
    return PracticeState(
      isLoadingQuestions: isLoadingQuestions ?? this.isLoadingQuestions,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSessionSubmitting: isSessionSubmitting ?? this.isSessionSubmitting,
      isSessionSubmitted: isSessionSubmitted ?? this.isSessionSubmitted,
      isTimeout: isTimeout ?? this.isTimeout,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      validationError: clearValidationError
          ? null
          : (validationError ?? this.validationError),
      user: user ?? this.user,
      sessionRole: sessionRole ?? this.sessionRole,
      shouldShowPaywall: clearPaywallRequest
          ? false
          : (shouldShowPaywall ?? this.shouldShowPaywall),
      paywallFeatureName: clearPaywallRequest
          ? null
          : (paywallFeatureName ?? this.paywallFeatureName),
      paywallMessage: clearPaywallRequest
          ? null
          : (paywallMessage ?? this.paywallMessage),
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      evaluations: evaluations ?? this.evaluations,
    );
  }
}
