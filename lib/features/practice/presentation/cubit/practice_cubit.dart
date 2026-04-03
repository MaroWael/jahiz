import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jahiz/features/home/models/home_user.dart';
import 'package:jahiz/features/home/services/local_storage_service.dart';
import 'package:jahiz/features/home/services/local_user_service.dart';
import 'package:jahiz/features/home/services/question_service.dart';
import 'package:jahiz/features/practice/models/practice_evaluation.dart';
import 'package:jahiz/features/practice/presentation/cubit/practice_state.dart';

class PracticeCubit extends Cubit<PracticeState> {
  PracticeCubit({
    LocalUserService? localUserService,
    QuestionService? questionService,
    LocalStorageService? localStorageService,
  }) : _localUserService = localUserService ?? LocalUserService(),
       _questionService = questionService ?? QuestionService(),
       _localStorageService = localStorageService ?? LocalStorageService(),
       super(const PracticeState());

  static const int minCharacters = 40;

  final LocalUserService _localUserService;
  final QuestionService _questionService;
  final LocalStorageService _localStorageService;

  Future<void> initialize({bool forceRefresh = false}) async {
    emit(
      state.copyWith(
        isLoadingQuestions: true,
        isTimeout: false,
        clearError: true,
        clearValidationError: true,
      ),
    );

    try {
      final user = await _localUserService.getCurrentUser();

      if (!forceRefresh) {
        final restored = await _tryRestoreProgress(user);
        if (restored) {
          return;
        }
      }

      final questions = await _questionService
          .getPracticeQuestions(
            role: user.role,
            level: user.level,
            techStack: user.techStack,
          )
          .timeout(const Duration(seconds: 12));

      emit(
        state.copyWith(
          isLoadingQuestions: false,
          user: user,
          questions: questions,
          currentIndex: 0,
          answers: const <int, String>{},
          evaluations: const <int, PracticeEvaluation>{},
          isTimeout: false,
          clearError: true,
        ),
      );
    } on TimeoutException {
      emit(
        state.copyWith(
          isLoadingQuestions: false,
          isTimeout: true,
          errorMessage: 'Request timed out while loading questions.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoadingQuestions: false,
          isTimeout: false,
          errorMessage: 'Unable to load practice questions right now.',
        ),
      );
    }
  }

  Future<bool> _tryRestoreProgress(HomeUser user) async {
    final saved = await _localStorageService.getPracticeProgress();
    if (saved == null) {
      return false;
    }

    final role = (saved['role'] ?? '').toString();
    final level = (saved['level'] ?? '').toString();
    if (role != user.role || level != user.level) {
      return false;
    }

    final rawQuestions = (saved['questions'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();

    if (rawQuestions.isEmpty) {
      return false;
    }

    final answers = <int, String>{};
    final rawAnswers = saved['answers'];
    if (rawAnswers is Map<String, dynamic>) {
      for (final entry in rawAnswers.entries) {
        final key = int.tryParse(entry.key);
        if (key != null) {
          answers[key] = entry.value.toString();
        }
      }
    }

    final evaluations = <int, PracticeEvaluation>{};
    final rawEvaluations = saved['evaluations'];
    if (rawEvaluations is Map<String, dynamic>) {
      for (final entry in rawEvaluations.entries) {
        final key = int.tryParse(entry.key);
        if (key == null || entry.value is! Map<String, dynamic>) {
          continue;
        }
        final value = entry.value as Map<String, dynamic>;
        final score = (value['score'] is num)
            ? (value['score'] as num).toDouble()
            : double.tryParse((value['score'] ?? '').toString()) ?? 0;

        evaluations[key] = PracticeEvaluation(
          score: score,
          feedback: (value['feedback'] ?? '').toString(),
          modelAnswer: (value['modelAnswer'] ?? '').toString(),
        );
      }
    }

    final currentIndexRaw = saved['currentIndex'];
    final currentIndex = currentIndexRaw is int
        ? currentIndexRaw
        : int.tryParse(currentIndexRaw?.toString() ?? '') ?? 0;

    emit(
      state.copyWith(
        isLoadingQuestions: false,
        user: user,
        questions: rawQuestions,
        currentIndex: currentIndex.clamp(0, rawQuestions.length - 1),
        answers: answers,
        evaluations: evaluations,
        isTimeout: false,
        clearError: true,
      ),
    );

    return true;
  }

  void updateCurrentAnswer(String value) {
    final updated = Map<int, String>.from(state.answers);
    updated[state.currentIndex] = value;
    emit(
      state.copyWith(
        answers: updated,
        clearValidationError: true,
      ),
    );
  }

  Future<void> submitCurrentAnswer() async {
    final user = state.user;
    if (user == null || !state.hasQuestions) {
      return;
    }

    final answer = state.currentAnswer.trim();
    if (answer.isEmpty) {
      emit(
        state.copyWith(
          validationError: 'Answer cannot be empty.',
        ),
      );
      return;
    }

    if (answer.length < minCharacters) {
      emit(
        state.copyWith(
          validationError:
              'Please write at least $minCharacters characters for a meaningful answer.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isSubmitting: true,
        clearValidationError: true,
        clearError: true,
      ),
    );

    try {
      final evaluation = await _questionService
          .evaluatePracticeAnswer(
            role: user.role,
            level: user.level,
            techStack: user.techStack,
            question: state.currentQuestion,
            answer: answer,
          )
          .timeout(const Duration(seconds: 15));

      final updated = Map<int, PracticeEvaluation>.from(state.evaluations);
      updated[state.currentIndex] = evaluation;

      emit(
        state.copyWith(
          isSubmitting: false,
          evaluations: updated,
        ),
      );

      await saveProgress();
    } on TimeoutException {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage:
              'AI evaluation timed out. Please retry in a moment.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to evaluate your answer. Please retry.',
        ),
      );
    }
  }

  void nextQuestion() {
    if (state.currentIndex >= state.questions.length - 1) {
      return;
    }

    emit(
      state.copyWith(
        currentIndex: state.currentIndex + 1,
        clearValidationError: true,
        clearError: true,
      ),
    );
  }

  void previousQuestion() {
    if (state.currentIndex <= 0) {
      return;
    }

    emit(
      state.copyWith(
        currentIndex: state.currentIndex - 1,
        clearValidationError: true,
        clearError: true,
      ),
    );
  }

  Future<void> retryLoadingQuestions() async {
    await initialize(forceRefresh: true);
  }

  Future<void> saveProgress() async {
    final user = state.user;
    if (user == null || !state.hasQuestions) {
      return;
    }

    final serializedEvaluations = <String, Map<String, dynamic>>{};
    for (final entry in state.evaluations.entries) {
      serializedEvaluations[entry.key.toString()] = <String, dynamic>{
        'score': entry.value.score,
        'feedback': entry.value.feedback,
        'modelAnswer': entry.value.modelAnswer,
      };
    }

    final serializedAnswers = <String, String>{};
    for (final entry in state.answers.entries) {
      serializedAnswers[entry.key.toString()] = entry.value;
    }

    await _localStorageService.savePracticeProgress(<String, dynamic>{
      'role': user.role,
      'level': user.level,
      'techStack': user.techStack,
      'questions': state.questions,
      'currentIndex': state.currentIndex,
      'answers': serializedAnswers,
      'evaluations': serializedEvaluations,
    });
  }

  Future<void> discardProgress() async {
    await _localStorageService.clearPracticeProgress();
  }
}
