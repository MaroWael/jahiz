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
  int _roleRotationStart = 0;
  List<String> _latestRolePool = const <String>[];
  static const int _rolesPerRefresh = 6;

  static const List<String> _realJobRolePool = <String>[
    'Frontend Developer',
    'Backend Developer',
    'Full Stack Developer',
    'Mobile Developer',
    'DevOps Engineer',
    'Cybersecurity Engineer',
    'Data Engineer',
    'QA Engineer',
    'Cloud Engineer',
    'Site Reliability Engineer',
    'Platform Engineer',
    'Machine Learning Engineer',
    'Data Scientist',
    'AI Engineer',
    'Product Manager',
    'Technical Product Manager',
    'Business Analyst',
    'Systems Analyst',
    'UI Designer',
    'UX Designer',
    'UI/UX Designer',
    'Solutions Architect',
    'Software Architect',
    'Network Engineer',
    'Security Analyst',
    'Security Operations Engineer',
    'Penetration Tester',
    'Cloud Security Engineer',
    'Database Administrator',
    'Data Analyst',
    'BI Developer',
    'Game Developer',
    'Embedded Systems Engineer',
    'IoT Engineer',
    'AR/VR Developer',
    'Android Developer',
    'iOS Developer',
    'Flutter Developer',
    'React Developer',
    'Node.js Developer',
    'Java Developer',
    'Python Developer',
    'Go Developer',
    '.NET Developer',
    'PHP Developer',
    'Ruby on Rails Developer',
    'Blockchain Developer',
    'ERP Consultant',
    'Salesforce Developer',
    'SAP Consultant',
    'MLOps Engineer',
    'Prompt Engineer',
  ];

  Future<List<String>> getPopularRoles({
    required String currentRole,
    required String level,
    required List<String> techStack,
  }) async {
    var generatedRoles = <String>[];

    try {
      generatedRoles = await _aiService.generatePopularRoles(
        currentRole: currentRole,
        level: level,
        techStack: techStack,
      );
    } catch (_) {
      // Fall back to personalized local suggestions when Gemini is unavailable.
    }

    final rolePool = _buildRolePool(
      currentRole: currentRole,
      techStack: techStack,
      generatedRoles: generatedRoles,
    );
    _latestRolePool = rolePool;

    return _nextRoleWindow(rolePool);
  }

  List<String> getLatestRolePool() {
    if (_latestRolePool.isNotEmpty) {
      return List<String>.from(_latestRolePool);
    }

    return List<String>.from(_realJobRolePool);
  }

  List<String> _buildRolePool({
    required String currentRole,
    required List<String> techStack,
    required List<String> generatedRoles,
  }) {
    final stackHints = techStack
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map((item) => '$item Developer');

    final merged = <String>{
      if (currentRole.trim().isNotEmpty) currentRole.trim(),
      ...generatedRoles
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty),
      ...stackHints,
      ..._realJobRolePool,
    };

    return merged.toList();
  }

  List<String> _nextRoleWindow(List<String> rolePool) {
    if (rolePool.isEmpty) {
      return <String>[];
    }

    if (rolePool.length <= _rolesPerRefresh) {
      return rolePool;
    }

    final start = _roleRotationStart % rolePool.length;
    final window = <String>[];

    for (var i = 0; i < _rolesPerRefresh; i++) {
      window.add(rolePool[(start + i) % rolePool.length]);
    }

    _roleRotationStart =
        (_roleRotationStart + _rolesPerRefresh) % rolePool.length;

    return window;
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
    final generated = await _aiService.generatePracticeQuestions(
      role: role,
      level: level,
      techStack: techStack,
      count: count,
    );

    if (generated.isEmpty) {
      throw Exception('No practice questions returned from Gemini.');
    }

    return generated;
  }

  Future<PracticeEvaluation> evaluatePracticeAnswer({
    required String role,
    required String level,
    required List<String> techStack,
    required String question,
    required String answer,
  }) async {
    return _aiService.evaluateAnswer(
      role: role,
      level: level,
      techStack: techStack,
      question: question,
      answer: answer,
    );
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
