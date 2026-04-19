import 'package:jahiz/core/services/auth_service.dart';
import 'package:jahiz/features/home/models/practice_session_record.dart';
import 'package:jahiz/features/home/services/practice_session_service.dart';
import 'package:jahiz/core/services/user_profile_service.dart';
import 'package:jahiz/features/home/services/local_storage_service.dart';

class ProfileManagementData {
  const ProfileManagementData({
    required this.name,
    required this.email,
    required this.role,
    required this.level,
    required this.techStack,
    required this.isPremium,
  });

  final String name;
  final String email;
  final String role;
  final String level;
  final List<String> techStack;
  final bool isPremium;
}

class ProfileManagementController {
  ProfileManagementController({
    AuthService? authService,
    UserProfileService? userProfileService,
    LocalStorageService? localStorageService,
    PracticeSessionService? practiceSessionService,
  }) : _authService = authService ?? AuthService(),
       _userProfileService = userProfileService ?? UserProfileService(),
       _localStorageService = localStorageService ?? LocalStorageService(),
       _practiceSessionService =
           practiceSessionService ?? PracticeSessionService();

  final AuthService _authService;
  final UserProfileService _userProfileService;
  final LocalStorageService _localStorageService;
  final PracticeSessionService _practiceSessionService;

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
    final resolvedName = (user.displayName ?? '').trim().isNotEmpty
        ? user.displayName!.trim()
        : (resolvedEmail.split('@').first.trim().isNotEmpty
              ? resolvedEmail.split('@').first.trim()
              : 'User');

    final role = (careerTarget['targetRole'] as String? ?? '').trim();
    final level = (careerTarget['level'] as String? ?? '').trim().toLowerCase();
    final techStack = rawTechStack
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
    final isPremium = data['isPremium'] == true;

    return ProfileManagementData(
      name: resolvedName,
      email: resolvedEmail,
      role: role,
      level: level,
      techStack: techStack,
      isPremium: isPremium,
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

  Future<List<DateTime>> loadInterviewActivityDates({int days = 84}) async {
    final sessions = await _practiceSessionService.getCompletedSessions();
    final cutoff = DateTime.now().toUtc().subtract(Duration(days: days - 1));

    final dates = sessions
        .map((session) => session.date)
        .whereType<DateTime>()
        .where(
          (date) => date.toUtc().isAfter(cutoff) || _isSameUtcDay(date, cutoff),
        )
        .toList();

    return dates;
  }

  Future<List<PracticeSessionRecord>> loadCompletedSessions() {
    return _practiceSessionService.getCompletedSessions();
  }

  bool _isSameUtcDay(DateTime first, DateTime second) {
    final a = first.toUtc();
    final b = second.toUtc();
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
