import 'dart:convert';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jahiz/features/practice/models/practice_evaluation.dart';
import 'package:http/http.dart' as http;

class AIService {
  AIService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Prefers .env for local development; falls back to --dart-define.
  static const String _apiKeyFromDefine = String.fromEnvironment(
    'GEMINI_API_KEY',
  );

  String get _apiKey {
    final fromEnv = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    return _apiKeyFromDefine.trim();
  }

  static const List<String> _geminiModels = <String>[
    'gemini-2.5-flash',
    'gemini-1.5-flash',
    'gemini-2.0-flash',
  ];

  String _extractGeminiError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['error']?['message']?.toString();
        if (message != null && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      // Ignore parse failures and return fallback text.
    }

    final raw = response.body.trim();
    if (raw.isNotEmpty) {
      return raw;
    }

    return 'No error details returned by Gemini.';
  }

  Future<http.Response> _postToGemini({
    required Map<String, dynamic> body,
  }) async {
    http.Response? lastResponse;

    for (final model in _geminiModels) {
      for (var attempt = 0; attempt < 3; attempt++) {
        final response = await _client.post(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
          ),
          headers: <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        // Retry same model on transient rate limits.
        if (response.statusCode == 429) {
          lastResponse = response;
          if (attempt < 2) {
            final delaySeconds = pow(2, attempt).toInt();
            await Future<void>.delayed(Duration(seconds: delaySeconds));
            continue;
          }
          break;
        }

        // Retry next model only when endpoint/model is not found.
        if (response.statusCode == 404) {
          lastResponse = response;
          break;
        }

        return response;
      }
    }

    return lastResponse ??
        http.Response('Gemini request failed with no response.', 500);
  }

  Future<List<String>> generatePopularRoles({
    required String currentRole,
    required String level,
    required List<String> techStack,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Gemini API key is not configured.');
    }

    final stack = techStack.isEmpty ? 'general software' : techStack.join(', ');
    final prompt =
        'Given candidate profile role="$currentRole", level="$level", stack="$stack", '
        'generate exactly 5 relevant interview target job roles. '
        'Return only a JSON array of strings, no markdown, no explanation.';

    final response = await _postToGemini(
      body: <String, dynamic>{
        'contents': <Map<String, dynamic>>[
          <String, dynamic>{
            'parts': <Map<String, String>>[
              <String, String>{'text': prompt},
            ],
          },
        ],
        'generationConfig': <String, dynamic>{
          'temperature': 0.4,
          'responseMimeType': 'application/json',
        },
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 429) {
        throw Exception(
          'Gemini rate limit reached (429): ${_extractGeminiError(response)}',
        );
      }
      throw Exception(
        'Gemini role suggestion request failed (${response.statusCode}): ${_extractGeminiError(response)}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawText =
        data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    if (rawText == null || rawText.trim().isEmpty) {
      throw Exception('Gemini returned empty popular roles output.');
    }

    final roles = _parseRoleList(rawText);

    if (roles.isEmpty) {
      throw Exception('No roles parsed from Gemini output.');
    }

    return roles.take(5).toList();
  }

  List<String> _parseRoleList(String rawText) {
    final cleaned = rawText
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    // First attempt: direct JSON array parsing.
    try {
      final parsed = jsonDecode(cleaned);
      if (parsed is List) {
        final roles = parsed
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList();
        if (roles.isNotEmpty) {
          return roles;
        }
      }
    } catch (_) {
      // Fallback to extracting JSON array fragment or bullet/list lines.
    }

    final arrayMatch = RegExp(r'\[[\s\S]*\]').firstMatch(cleaned);
    if (arrayMatch != null) {
      final fragment = arrayMatch.group(0);
      if (fragment != null) {
        try {
          final parsed = jsonDecode(fragment);
          if (parsed is List) {
            final roles = parsed
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .toSet()
                .toList();
            if (roles.isNotEmpty) {
              return roles;
            }
          }
        } catch (_) {
          // Continue to line-based parsing.
        }
      }
    }

    final lineRoles = cleaned
        .split('\n')
        .map(
          (line) => line
              .replaceFirst(RegExp(r'^[-*\d\.)\s]+'), '')
              .replaceAll('"', '')
              .trim(),
        )
        .where((line) => line.isNotEmpty)
        .toSet()
        .toList();

    if (lineRoles.isNotEmpty) {
      return lineRoles;
    }

    throw Exception('Gemini roles output is not parseable.');
  }

  Future<String> generateDailyQuestion(String role, String level) async {
    if (_apiKey.isEmpty) {
      throw Exception('Gemini API key is not configured.');
    }

    final prompt =
        'Generate one concise interview question for role: $role, level: $level. Return question text only.';

    final response = await _postToGemini(
      body: <String, dynamic>{
        'contents': <Map<String, dynamic>>[
          <String, dynamic>{
            'parts': <Map<String, String>>[
              <String, String>{'text': prompt},
            ],
          },
        ],
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 429) {
        throw Exception(
          'Gemini rate limit reached (429): ${_extractGeminiError(response)}',
        );
      }
      throw Exception(
        'Gemini request failed (${response.statusCode}): ${_extractGeminiError(response)}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final question =
        data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

    if (question == null || question.trim().isEmpty) {
      throw Exception('Gemini returned an empty question.');
    }

    return question.trim();
  }

  Future<List<String>> generatePracticeQuestions({
    required String role,
    required String level,
    required List<String> techStack,
    int count = 5,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Gemini API key is not configured.');
    }

    final stack = techStack.isEmpty ? 'general software' : techStack.join(', ');
    final prompt =
        'Generate exactly $count interview practice questions for role="$role", level="$level", stack="$stack". '
        'Questions should be concise, practical, and technically focused. '
        'Return only a JSON array of strings with no markdown and no explanation.';

    final response = await _postToGemini(
      body: <String, dynamic>{
        'contents': <Map<String, dynamic>>[
          <String, dynamic>{
            'parts': <Map<String, String>>[
              <String, String>{'text': prompt},
            ],
          },
        ],
        'generationConfig': <String, dynamic>{
          'temperature': 0.5,
          'responseMimeType': 'application/json',
        },
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 429) {
        throw Exception(
          'Gemini rate limit reached (429): ${_extractGeminiError(response)}',
        );
      }
      throw Exception(
        'Gemini practice questions request failed (${response.statusCode}): ${_extractGeminiError(response)}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawText =
        data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    if (rawText == null || rawText.trim().isEmpty) {
      throw Exception('Gemini returned empty practice questions output.');
    }

    final roles = _parseRoleList(rawText);
    if (roles.isEmpty) {
      throw Exception('No practice questions parsed from Gemini output.');
    }

    return roles.take(count).toList();
  }

  Future<PracticeEvaluation> evaluateAnswer({
    required String role,
    required String level,
    required List<String> techStack,
    required String question,
    required String answer,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Gemini API key is not configured.');
    }

    final stack = techStack.isEmpty ? 'general software' : techStack.join(', ');
    final prompt =
        'You are an interview evaluator. Evaluate this candidate answer.\n'
        'Role: $role\n'
        'Level: $level\n'
        'Tech Stack: $stack\n'
        'Question: $question\n'
        'Candidate Answer: $answer\n\n'
        'Return strict JSON object with keys: score, feedback, modelAnswer. '
        'score must be a number from 0 to 10. feedback must be detailed and actionable. '
        'modelAnswer must be a strong example answer.';

    final response = await _postToGemini(
      body: <String, dynamic>{
        'contents': <Map<String, dynamic>>[
          <String, dynamic>{
            'parts': <Map<String, String>>[
              <String, String>{'text': prompt},
            ],
          },
        ],
        'generationConfig': <String, dynamic>{
          'temperature': 0.2,
          'responseMimeType': 'application/json',
        },
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 429) {
        throw Exception(
          'Gemini rate limit reached (429): ${_extractGeminiError(response)}',
        );
      }
      throw Exception(
        'Gemini evaluation request failed (${response.statusCode}): ${_extractGeminiError(response)}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawText =
        data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    if (rawText == null || rawText.trim().isEmpty) {
      throw Exception('Gemini returned empty evaluation output.');
    }

    final cleaned = rawText
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    final objectMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
    final payload = objectMatch?.group(0) ?? cleaned;

    final parsed = jsonDecode(payload) as Map<String, dynamic>;
    final rawScore = parsed['score'];
    final score = rawScore is num
        ? rawScore.toDouble()
        : double.tryParse(rawScore?.toString() ?? '') ?? 0;
    final feedback = (parsed['feedback'] ?? '').toString().trim();
    final modelAnswer = (parsed['modelAnswer'] ?? '').toString().trim();

    if (feedback.isEmpty || modelAnswer.isEmpty) {
      throw Exception('Gemini evaluation output is missing required fields.');
    }

    return PracticeEvaluation(
      score: score.clamp(0, 10).toDouble(),
      feedback: feedback,
      modelAnswer: modelAnswer,
    );
  }
}
