import 'dart:convert';

import 'package:flutter/services.dart';
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
}
