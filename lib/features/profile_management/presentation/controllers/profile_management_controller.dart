import 'package:jahiz/core/services/auth_service.dart';
import 'package:jahiz/core/services/user_profile_service.dart';
import 'package:jahiz/features/home/services/local_storage_service.dart';

class ProfileManagementData {
  const ProfileManagementData({
    required this.email,
    required this.role,
    required this.level,
    required this.techStack,
  });

  final String email;
  final String role;
  final String level;
  final List<String> techStack;
}

class ProfileManagementController {
  ProfileManagementController({
    AuthService? authService,
    UserProfileService? userProfileService,
    LocalStorageService? localStorageService,
  }) : _authService = authService ?? AuthService(),
       _userProfileService = userProfileService ?? UserProfileService(),
       _localStorageService = localStorageService ?? LocalStorageService();

  final AuthService _authService;
  final UserProfileService _userProfileService;
  final LocalStorageService _localStorageService;

  Future<ProfileManagementData> loadCurrentProfile() async {
    final user = _authService.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    final snapshot = await _userProfileService.getUserDocument(user.uid);
    final data = snapshot.data() ?? <String, dynamic>{};

    final careerTarget =
        data['careerTarget'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final rawTechStack =
        data['technicalStack'] as List<dynamic>? ?? const <dynamic>[];

    final emailFromFirestore = (data['email'] as String? ?? '').trim();
    final emailFromAuth = (user.email ?? '').trim();
    final resolvedEmail = emailFromFirestore.isNotEmpty
        ? emailFromFirestore
        : emailFromAuth;

    final role = (careerTarget['targetRole'] as String? ?? '').trim();
    final level = (careerTarget['level'] as String? ?? '').trim().toLowerCase();
    final techStack = rawTechStack
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();

    return ProfileManagementData(
      email: resolvedEmail,
      role: role,
      level: level,
      techStack: techStack,
    );
  }

  Future<void> updateProfile({
    required String role,
    required String level,
    required List<String> techStack,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    await _userProfileService.updateCareerProfile(
      uid: user.uid,
      role: role,
      level: level,
      technicalStack: techStack,
    );

    await _localStorageService.clearSelectedRole();
    await _localStorageService.clearCachedQuestion();
  }
}
