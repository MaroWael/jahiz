import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesService {
  static const String seenOnboardingKey = 'seen_onboarding';

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(seenOnboardingKey) ?? false;
  }

  Future<void> setSeenOnboarding(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(seenOnboardingKey, seen);
  }
}
