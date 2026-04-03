import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:jahiz/features/practice/models/practice_evaluation.dart';
import 'package:jahiz/features/home/services/ai_service.dart';
import 'package:jahiz/features/home/services/local_storage_service.dart';

class QuestionService {
  QuestionService({
    AIService? aiService,
    LocalStorageService? localStorageService,
  }) : _aiService = aiService ?? AIService(),
       _localStorageService = localStorageService ?? LocalStorageService();

  final AIService _aiService;
  final LocalStorageService _localStorageService;

  Future<List<String>> getPopularRoles({
    required String currentRole,
    required String level,
    required List<String> techStack,
  }) async {
    try {
      final roles = await _aiService.generatePopularRoles(
        currentRole: currentRole,
        level: level,
        techStack: techStack,
      );

      if (roles.isNotEmpty) {
        return roles;
      }
    } catch (_) {
      // Fall back to personalized local suggestions when Gemini is unavailable.
    }

    return _buildPersonalizedRoleFallback(
      currentRole: currentRole,
      techStack: techStack,
    );
  }

  List<String> _buildPersonalizedRoleFallback({
    required String currentRole,
    required List<String> techStack,
  }) {
    final normalizedRole = currentRole.trim();
    final firstStack = techStack.isNotEmpty ? techStack.first.trim() : '';
    final stackLabel = firstStack.isEmpty ? 'Software' : firstStack;

    final suggestions = <String>{
      if (normalizedRole.isNotEmpty) normalizedRole,
      '$stackLabel Developer',
      '$stackLabel Engineer',
      'Senior $stackLabel Developer',
      'Full Stack Developer',
      'Software Engineer',
    };

    return suggestions.where((item) => item.trim().isNotEmpty).take(5).toList();
  }

  Future<String> getDailyQuestion({
    required String role,
    required String level,
    required List<String> techStack,
  }) async {
    final now = DateTime.now();
    final cachedQuestion = await _localStorageService.getCachedQuestion();
    final lastGenerated = await _localStorageService.getLastGeneratedDate();

    if (cachedQuestion != null &&
        lastGenerated != null &&
        _isSameDay(lastGenerated, now)) {
      return cachedQuestion;
    }

    try {
      final stackRole = techStack.isNotEmpty ? techStack.first : role;
      final generated = await _aiService.generateDailyQuestion(
        stackRole,
        level,
      );
      await _localStorageService.saveQuestion(
        question: generated,
        generatedAt: now,
      );
      return generated;
    } catch (_) {
      if (cachedQuestion != null && cachedQuestion.isNotEmpty) {
        return cachedQuestion;
      }

      final fallback = await _loadFallbackQuestion(techStack);
      await _localStorageService.saveQuestion(
        question: fallback,
        generatedAt: now,
      );
      return fallback;
    }
  }

  Future<String> _loadFallbackQuestion(List<String> techStack) async {
    final raw = await rootBundle.loadString(
      'assets/questions/fallback_questions.json',
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    final stackKeys = techStack.map((item) => item.toLowerCase()).toList();
    for (final key in stackKeys) {
      final values = decoded[key];
      if (values is List && values.isNotEmpty) {
        return values.first.toString();
      }
    }

    final frontend = decoded['frontend'];
    if (frontend is List && frontend.isNotEmpty) {
      return frontend.first.toString();
    }

    return 'Tell me about a challenging project and your key technical decisions.';
  }

  bool _isSameDay(DateTime first, DateTime second) {
    final a = first.toLocal();
    final b = second.toLocal();
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<List<String>> getPracticeQuestions({
    required String role,
    required String level,
    required List<String> techStack,
    int count = 5,
  }) async {
    try {
      final generated = await _aiService.generatePracticeQuestions(
        role: role,
        level: level,
        techStack: techStack,
        count: count,
      );
      if (generated.isNotEmpty) {
        return generated;
      }
    } catch (_) {
      // Fall back to local sample questions if Gemini is unavailable.
    }

    return _buildFallbackPracticeQuestions(techStack: techStack, count: count);
  }

  Future<PracticeEvaluation> evaluatePracticeAnswer({
    required String role,
    required String level,
    required List<String> techStack,
    required String question,
    required String answer,
  }) async {
    try {
      return await _aiService.evaluateAnswer(
        role: role,
        level: level,
        techStack: techStack,
        question: question,
        answer: answer,
      );
    } catch (_) {
      return PracticeEvaluation(
        score: 6,
        feedback:
            'Your answer has a good start but can be more structured. Explain the context, your technical decision, trade-offs, and measurable impact.',
        modelAnswer:
            'A strong answer should state the problem, your approach, key technologies used, trade-offs considered, and the final impact in production.',
      );
    }
  }

  Future<List<String>> _buildFallbackPracticeQuestions({
    required List<String> techStack,
    required int count,
  }) async {
    final raw = await rootBundle.loadString(
      'assets/questions/fallback_questions.json',
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    final aggregate = <String>[];
    final keys = techStack.map((item) => item.toLowerCase()).toList();
    for (final key in keys) {
      final values = decoded[key];
      if (values is List) {
        aggregate.addAll(values.map((item) => item.toString()));
      }
    }

    final frontend = decoded['frontend'];
    if (frontend is List) {
      aggregate.addAll(frontend.map((item) => item.toString()));
    }

    if (aggregate.isEmpty) {
      aggregate.addAll(<String>[
        'Walk me through a project where you handled a technical trade-off.',
        'How do you debug a production issue under time pressure?',
        'How do you design a scalable feature from scratch?',
      ]);
    }

    aggregate.shuffle(Random());
    return aggregate.take(count).toList();
  }
}
