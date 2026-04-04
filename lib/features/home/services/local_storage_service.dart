import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String cachedQuestionKey = 'home_cached_question';
  static const String lastGeneratedDateKey = 'home_last_generated_date';
  static const String selectedRoleKey = 'home_selected_role';
  static const String practiceProgressKey = 'practice_progress';

  Future<String?> getCachedQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(cachedQuestionKey);
  }

  Future<DateTime?> getLastGeneratedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(lastGeneratedDateKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<void> saveQuestion({
    required String question,
    required DateTime generatedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cachedQuestionKey, question);
    await prefs.setString(lastGeneratedDateKey, generatedAt.toIso8601String());
  }

  Future<void> saveSelectedRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(selectedRoleKey, role);
  }

  Future<String?> getSelectedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(selectedRoleKey);
  }

  Future<void> savePracticeProgress(Map<String, dynamic> progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(practiceProgressKey, jsonEncode(progress));
  }

  Future<Map<String, dynamic>?> getPracticeProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(practiceProgressKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return null;
  }

  Future<void> clearPracticeProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(practiceProgressKey);
  }
}
