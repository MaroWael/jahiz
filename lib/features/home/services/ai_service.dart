import 'dart:convert';

import 'package:http/http.dart' as http;

class AIService {
  AIService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Uses a compile-time define to avoid hardcoding secrets in source.
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

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

    final response = await _client.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey',
      ),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
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
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Gemini role suggestion request failed (${response.statusCode}).',
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

    final response = await _client.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey',
      ),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'contents': <Map<String, dynamic>>[
          <String, dynamic>{
            'parts': <Map<String, String>>[
              <String, String>{'text': prompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gemini request failed (${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final question =
        data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

    if (question == null || question.trim().isEmpty) {
      throw Exception('Gemini returned an empty question.');
    }

    return question.trim();
  }
}
