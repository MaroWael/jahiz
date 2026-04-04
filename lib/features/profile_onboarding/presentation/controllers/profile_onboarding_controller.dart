import 'package:jahiz/core/services/auth_service.dart';
import 'package:jahiz/core/services/user_profile_service.dart';

class ProfileOnboardingController {
  ProfileOnboardingController({
    AuthService? authService,
    UserProfileService? userProfileService,
  }) : _authService = authService ?? AuthService(),
       _userProfileService = userProfileService ?? UserProfileService();

  final AuthService _authService;
  final UserProfileService _userProfileService;

  Future<void> saveOnboardingData({
    required String userType,
    required Map<String, dynamic> studentInfo,
    required Map<String, dynamic> professionalInfo,
    required Map<String, dynamic> careerTarget,
    required List<String> technicalStack,
    required Map<String, dynamic> socialLinks,
    required String interviewLanguage,
  }) async {
    final user = _authService.currentUser;
    if (user == null || user.email == null) {
      throw StateError('Unable to identify the current user.');
    }

    await _userProfileService.saveOnboardingData(
      uid: user.uid,
      email: user.email!,
      userType: userType,
      studentInfo: studentInfo,
      professionalInfo: professionalInfo,
      careerTarget: careerTarget,
      technicalStack: technicalStack,
      socialLinks: socialLinks,
      interviewLanguage: interviewLanguage,
    );
  }
}
