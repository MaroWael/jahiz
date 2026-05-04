import 'package:flutter/material.dart';
import 'package:jahiz/core/services/app_preferences_service.dart';

class AppThemeController {
  AppThemeController._();

  static final AppThemeController instance = AppThemeController._();

  final AppPreferencesService _preferences = AppPreferencesService();
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  Future<void> loadThemeMode() async {
    themeMode.value = await _preferences.getThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (themeMode.value == mode) {
      return;
    }

    themeMode.value = mode;
    await _preferences.setThemeMode(mode);
  }
}
