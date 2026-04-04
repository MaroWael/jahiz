import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jahiz/features/home/models/session_summary.dart';
import 'package:jahiz/features/home/presentation/cubit/home_state.dart';
import 'package:jahiz/features/home/services/local_storage_service.dart';
import 'package:jahiz/features/home/services/local_user_service.dart';
import 'package:jahiz/features/home/services/question_service.dart';
import 'package:jahiz/features/home/services/session_summary_service.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    LocalUserService? localUserService,
    QuestionService? questionService,
    LocalStorageService? localStorageService,
    SessionSummaryService? sessionSummaryService,
  }) : _localUserService = localUserService ?? LocalUserService(),
       _questionService = questionService ?? QuestionService(),
       _localStorageService = localStorageService ?? LocalStorageService(),
       _sessionSummaryService =
           sessionSummaryService ?? SessionSummaryService(),
       super(const HomeState());

  final LocalUserService _localUserService;
  final QuestionService _questionService;
  final LocalStorageService _localStorageService;
  final SessionSummaryService _sessionSummaryService;

  Future<void> initialize() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final user = await _localUserService.getCurrentUser();
      await _localStorageService.clearSelectedRole();
      final selectedRole = await _localStorageService.getSelectedRole();
      final activeRole = selectedRole;

      final popularRoles = await _questionService.getPopularRoles(
        currentRole: user.role,
        level: user.level,
        techStack: user.techStack,
      );
      final allRoles = _questionService.getLatestRolePool();

      final question = await _questionService.getDailyQuestion(
        role: activeRole ?? user.role,
        level: user.level,
        techStack: user.techStack,
      );
      SessionSummary? sessionSummary;
      try {
        sessionSummary = await _sessionSummaryService.getLastSessionSummary();
      } catch (_) {
        sessionSummary = null;
      }

      emit(
        state.copyWith(
          isLoading: false,
          user: user,
          selectedRole: activeRole,
          searchQuery: '',
          coachMessage: activeRole == null
              ? 'Choose a role to start practicing'
              : 'Ready to practice for your $activeRole interview?',
          dailyQuestion: question,
          notificationCount: 3,
          sessionSummary: sessionSummary,
          popularRoles: popularRoles,
          allRoles: allRoles,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Unable to load home dashboard data.',
        ),
      );
    }
  }

  Future<void> selectRole(String role) async {
    final user = state.user;
    if (user == null) {
      return;
    }

    emit(state.copyWith(isLoading: true, selectedRole: role, clearError: true));

    try {
      await _localStorageService.saveSelectedRole(role);
      final question = await _questionService.getDailyQuestion(
        role: role,
        level: user.level,
        techStack: <String>[role],
      );

      emit(
        state.copyWith(
          isLoading: false,
          selectedRole: role,
          coachMessage: 'Ready to practice for your $role interview?',
          dailyQuestion: question,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to prepare role-specific questions.',
        ),
      );
    }
  }

  Future<void> updateSearchQuery(String query) async {
    await _localStorageService.clearSelectedRole();
    final cachedPool = _questionService.getLatestRolePool();

    emit(
      state.copyWith(
        searchQuery: query,
        selectedRole: null,
        allRoles: cachedPool,
      ),
    );
  }

  void updateTabIndex(int index) {
    emit(state.copyWith(activeTabIndex: index));
  }
}
