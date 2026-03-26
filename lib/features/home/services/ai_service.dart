import 'dart:convert';

import 'package:http/http.dart' as http;

class AIService {
  AIService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Uses a compile-time define to avoid hardcoding secrets in source.
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

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
