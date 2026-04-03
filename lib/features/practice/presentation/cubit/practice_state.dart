import 'package:jahiz/features/home/models/home_user.dart';
import 'package:jahiz/features/practice/models/practice_evaluation.dart';

class PracticeState {
  const PracticeState({
    this.isLoadingQuestions = false,
    this.isSubmitting = false,
    this.isTimeout = false,
    this.errorMessage,
    this.validationError,
    this.user,
    this.questions = const <String>[],
    this.currentIndex = 0,
    this.answers = const <int, String>{},
    this.evaluations = const <int, PracticeEvaluation>{},
  });

  final bool isLoadingQuestions;
  final bool isSubmitting;
  final bool isTimeout;
  final String? errorMessage;
  final String? validationError;
  final HomeUser? user;
  final List<String> questions;
  final int currentIndex;
  final Map<int, String> answers;
  final Map<int, PracticeEvaluation> evaluations;

  bool get hasQuestions => questions.isNotEmpty;

  String get currentQuestion => hasQuestions ? questions[currentIndex] : '';

  String get currentAnswer => answers[currentIndex] ?? '';

  PracticeEvaluation? get currentEvaluation => evaluations[currentIndex];

  PracticeState copyWith({
    bool? isLoadingQuestions,
    bool? isSubmitting,
    bool? isTimeout,
    String? errorMessage,
    String? validationError,
    HomeUser? user,
    List<String>? questions,
    int? currentIndex,
    Map<int, String>? answers,
    Map<int, PracticeEvaluation>? evaluations,
    bool clearError = false,
    bool clearValidationError = false,
  }) {
    return PracticeState(
      isLoadingQuestions: isLoadingQuestions ?? this.isLoadingQuestions,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isTimeout: isTimeout ?? this.isTimeout,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      validationError: clearValidationError
          ? null
          : (validationError ?? this.validationError),
      user: user ?? this.user,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      evaluations: evaluations ?? this.evaluations,
    );
  }
}
