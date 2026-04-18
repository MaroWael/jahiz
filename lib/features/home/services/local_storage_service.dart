import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const int freeDailyPracticeSessionLimit = 2;
  static const String cachedQuestionKey = 'home_cached_question';
  static const String lastGeneratedDateKey = 'home_last_generated_date';
  static const String selectedRoleKey = 'home_selected_role';
  static const String practiceProgressKey = 'practice_progress';
  static const String dailyQuestionUsageCountPrefix =
      'daily_question_usage_count';
  static const String dailyQuestionUsageDatePrefix =
      'daily_question_usage_date';
  static const String dailyPracticeSessionUsageCountPrefix =
      'daily_practice_session_usage_count';
  static const String dailyPracticeSessionUsageDatePrefix =
      'daily_practice_session_usage_date';

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

  Future<void> clearSelectedRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(selectedRoleKey);
  }

  Future<int> getDailyQuestionUsageCount({
    required String uid,
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _resetDailyQuestionUsageIfNeeded(prefs: prefs, uid: uid, now: now);
    return prefs.getInt(_dailyQuestionUsageCountKey(uid)) ?? 0;
  }

  Future<int> incrementDailyQuestionUsage({
    required String uid,
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _resetDailyQuestionUsageIfNeeded(prefs: prefs, uid: uid, now: now);

    final countKey = _dailyQuestionUsageCountKey(uid);
    final next = (prefs.getInt(countKey) ?? 0) + 1;
    await prefs.setInt(countKey, next);
    return next;
  }

  Future<void> clearDailyQuestionUsage({required String uid}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dailyQuestionUsageCountKey(uid));
    await prefs.remove(_dailyQuestionUsageDateKey(uid));
  }

  Future<int> getDailyPracticeSessionUsageCount({
    required String uid,
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _resetDailyPracticeSessionUsageIfNeeded(
      prefs: prefs,
      uid: uid,
      now: now,
    );
    return prefs.getInt(_dailyPracticeSessionUsageCountKey(uid)) ?? 0;
  }

  Future<int> incrementDailyPracticeSessionUsage({
    required String uid,
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _resetDailyPracticeSessionUsageIfNeeded(
      prefs: prefs,
      uid: uid,
      now: now,
    );

    final countKey = _dailyPracticeSessionUsageCountKey(uid);
    final next = (prefs.getInt(countKey) ?? 0) + 1;
    await prefs.setInt(countKey, next);
    return next;
  }

  Future<void> clearDailyPracticeSessionUsage({required String uid}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dailyPracticeSessionUsageCountKey(uid));
    await prefs.remove(_dailyPracticeSessionUsageDateKey(uid));
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

  Future<void> _resetDailyQuestionUsageIfNeeded({
    required SharedPreferences prefs,
    required String uid,
    DateTime? now,
  }) async {
    final currentDayStamp = _toDayStamp(now ?? DateTime.now());
    final dayKey = _dailyQuestionUsageDateKey(uid);
    final existingDayStamp = prefs.getString(dayKey);

    if (existingDayStamp == currentDayStamp) {
      return;
    }

    await prefs.setString(dayKey, currentDayStamp);
    await prefs.setInt(_dailyQuestionUsageCountKey(uid), 0);
  }

  Future<void> _resetDailyPracticeSessionUsageIfNeeded({
    required SharedPreferences prefs,
    required String uid,
    DateTime? now,
  }) async {
    final currentDayStamp = _toDayStamp(now ?? DateTime.now());
    final dayKey = _dailyPracticeSessionUsageDateKey(uid);
    final existingDayStamp = prefs.getString(dayKey);

    if (existingDayStamp == currentDayStamp) {
      return;
    }

    await prefs.setString(dayKey, currentDayStamp);
    await prefs.setInt(_dailyPracticeSessionUsageCountKey(uid), 0);
  }

  String _toDayStamp(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  String _dailyQuestionUsageCountKey(String uid) {
    return '${dailyQuestionUsageCountPrefix}_$uid';
  }

  String _dailyQuestionUsageDateKey(String uid) {
    return '${dailyQuestionUsageDatePrefix}_$uid';
  }

  String _dailyPracticeSessionUsageCountKey(String uid) {
    return '${dailyPracticeSessionUsageCountPrefix}_$uid';
  }

  String _dailyPracticeSessionUsageDateKey(String uid) {
    return '${dailyPracticeSessionUsageDatePrefix}_$uid';
  }
}
