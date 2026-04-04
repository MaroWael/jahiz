import 'package:jahiz/core/services/app_preferences_service.dart';
import 'package:jahiz/core/services/auth_service.dart';
import 'package:jahiz/core/services/user_profile_service.dart';

enum StartupDestination {
  onboarding,
  auth,
  emailVerification,
  home,
  profileOnboarding,
}

class StartupRouteService {
  StartupRouteService({
    AuthService? authService,
    UserProfileService? userProfileService,
    AppPreferencesService? appPreferencesService,
  }) : _authService = authService ?? AuthService(),
       _userProfileService = userProfileService ?? UserProfileService(),
       _appPreferencesService =
           appPreferencesService ?? AppPreferencesService();

  final AuthService _authService;
  final UserProfileService _userProfileService;
  final AppPreferencesService _appPreferencesService;

  Future<StartupDestination> resolveDestination() async {
    final seenOnboarding = await _appPreferencesService.hasSeenOnboarding();
    if (!seenOnboarding) {
      return StartupDestination.onboarding;
    }

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return StartupDestination.auth;
    }

    final usesEmailPassword = currentUser.providerData.any(
      (provider) => provider.providerId == 'password',
    );

    if (usesEmailPassword && !currentUser.emailVerified) {
      return StartupDestination.emailVerification;
    }

    final hasCompleted = await _userProfileService.hasCompletedOnboarding(
      currentUser.uid,
    );

    return hasCompleted
        ? StartupDestination.home
        : StartupDestination.profileOnboarding;
  }
}
