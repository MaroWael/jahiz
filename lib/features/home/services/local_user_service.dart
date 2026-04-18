import 'package:firebase_auth/firebase_auth.dart';
import 'package:jahiz/core/services/user_profile_service.dart';
import 'package:jahiz/features/home/models/home_user.dart';

class LocalUserService {
  LocalUserService({FirebaseAuth? auth, UserProfileService? userProfileService})
    : _auth = auth ?? FirebaseAuth.instance,
      _userProfileService = userProfileService ?? UserProfileService();

  final FirebaseAuth _auth;
  final UserProfileService _userProfileService;

  User? get authenticatedUser => _auth.currentUser;

  Future<HomeUser> getCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('No authenticated user found.');
    }

    final snapshot = await _userProfileService.getUserDocument(currentUser.uid);
    final data = snapshot.data() ?? <String, dynamic>{};

    final careerTarget =
        data['careerTarget'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final rawTechStack =
        data['technicalStack'] as List<dynamic>? ?? <dynamic>[];
    final techStack = rawTechStack
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final displayName = (currentUser.displayName ?? '').trim();
    final emailPrefix = (currentUser.email ?? '').split('@').first.trim();
    final resolvedName = displayName.isNotEmpty
        ? displayName
        : (emailPrefix.isNotEmpty ? emailPrefix : 'User');

    final role = (careerTarget['targetRole'] as String? ?? 'Software Engineer')
        .trim();
    final level = (careerTarget['level'] as String? ?? 'Junior').trim();
    final isPremium = data['isPremium'] == true;

    return HomeUser(
      name: resolvedName,
      role: role.isEmpty ? 'Software Engineer' : role,
      level: level.isEmpty ? 'Junior' : level,
      techStack: techStack,
      isPremium: isPremium,
    );
  }
}
