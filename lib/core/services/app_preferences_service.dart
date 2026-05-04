import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationPermissionState { unknown, granted, denied }

class AppPreferencesService {
  static const String seenOnboardingKey = 'seen_onboarding';
  static const String notificationPermissionStateKey =
      'notification_permission_state';
  static const String dailyPracticeReminderScheduledKey =
      'daily_practice_reminder_scheduled';
  static const String lastKnownTimeZoneKey = 'notification_last_timezone';
  static const String themeModeKey = 'theme_mode';

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(seenOnboardingKey) ?? false;
  }

  Future<void> setSeenOnboarding(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(seenOnboardingKey, seen);
  }

  Future<NotificationPermissionState> getNotificationPermissionState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(notificationPermissionStateKey);
    return _notificationStateFromString(raw);
  }

  Future<void> setNotificationPermissionState(
    NotificationPermissionState state,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(notificationPermissionStateKey, state.name);
  }

  Future<bool> isDailyPracticeReminderScheduled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(dailyPracticeReminderScheduledKey) ?? false;
  }

  Future<void> setDailyPracticeReminderScheduled(bool scheduled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(dailyPracticeReminderScheduledKey, scheduled);
  }

  Future<String?> getLastKnownTimeZone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(lastKnownTimeZoneKey);
  }

  Future<void> setLastKnownTimeZone(String? timeZone) async {
    final prefs = await SharedPreferences.getInstance();
    if (timeZone == null || timeZone.isEmpty) {
      await prefs.remove(lastKnownTimeZoneKey);
      return;
    }
    await prefs.setString(lastKnownTimeZoneKey, timeZone);
  }

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(themeModeKey);
    return _themeModeFromString(raw);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeModeKey, mode.name);
  }

  NotificationPermissionState _notificationStateFromString(String? value) {
    switch (value) {
      case 'granted':
        return NotificationPermissionState.granted;
      case 'denied':
        return NotificationPermissionState.denied;
      default:
        return NotificationPermissionState.unknown;
    }
  }

  ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }
}
