import 'package:firebase_auth/firebase_auth.dart';
import 'package:jahiz/core/services/auth_service.dart';
import 'package:jahiz/core/services/user_profile_service.dart';

enum PostAuthDestination { auth, emailVerification, home, profileOnboarding }

class AuthFlowController {
  AuthFlowController({
    AuthService? authService,
    UserProfileService? userProfileService,
  }) : _authService = authService ?? AuthService(),
       _userProfileService = userProfileService ?? UserProfileService();

  final AuthService _authService;
  final UserProfileService _userProfileService;

  String get currentUserEmail => _authService.currentUser?.email ?? '';

  Future<PostAuthDestination> authenticateWithEmail({
    required bool isRegisterMode,
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (isRegisterMode) {
      final credential = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
      );

      final registeredUser = credential.user;
      if (registeredUser != null) {
        await _userProfileService.ensureUserDocumentDefaults(
          uid: registeredUser.uid,
          email: registeredUser.email,
        );
      }

      return PostAuthDestination.emailVerification;
    }

    final credential = await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    final usesEmailPassword = user?.providerData.any(
      (provider) => provider.providerId == 'password',
    );

    if (user != null && usesEmailPassword == true && !user.emailVerified) {
      return PostAuthDestination.emailVerification;
    }

    return _resolvePostAuthDestination(user);
  }

  Future<PostAuthDestination> authenticateWithGoogle() async {
    final credential = await _authService.signInWithGoogle();
    return _resolvePostAuthDestination(credential.user);
  }

  Future<PostAuthDestination> refreshVerificationStatus() async {
    await _authService.reloadCurrentUser();
    final user = _authService.currentUser;

    if (user == null) {
      return PostAuthDestination.auth;
    }

    if (!user.emailVerified) {
      return PostAuthDestination.emailVerification;
    }

    return _resolvePostAuthDestination(user);
  }

  Future<void> resendVerificationEmail() async {
    await _authService.sendEmailVerification();
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _authService.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<PostAuthDestination> _resolvePostAuthDestination(User? user) async {
    if (user == null) {
      return PostAuthDestination.auth;
    }

    await _userProfileService.ensureUserDocumentDefaults(
      uid: user.uid,
      email: user.email,
    );

    final hasCompleted = await _userProfileService.hasCompletedOnboarding(
      user.uid,
    );

    return hasCompleted
        ? PostAuthDestination.home
        : PostAuthDestination.profileOnboarding;
  }
}
