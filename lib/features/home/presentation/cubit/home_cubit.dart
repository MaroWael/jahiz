import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jahiz/features/home/models/session_summary.dart';
import 'package:jahiz/features/home/presentation/cubit/home_state.dart';
import 'package:jahiz/features/home/services/local_storage_service.dart';
import 'package:jahiz/features/home/services/local_user_service.dart';
import 'package:jahiz/features/home/services/question_service.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    LocalUserService? localUserService,
    QuestionService? questionService,
    LocalStorageService? localStorageService,
  }) : _localUserService = localUserService ?? LocalUserService(),
       _questionService = questionService ?? QuestionService(),
       _localStorageService = localStorageService ?? LocalStorageService(),
       super(const HomeState());

  final LocalUserService _localUserService;
  final QuestionService _questionService;
  final LocalStorageService _localStorageService;

  Future<void> initialize() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final user = await _localUserService.getCurrentUser();
      final selectedRole = await _localStorageService.getSelectedRole();
      final activeRole = selectedRole ?? user.role;

      final popularRoles = await _questionService.getPopularRoles(
        currentRole: user.role,
        level: user.level,
        techStack: user.techStack,
      );

      final question = await _questionService.getDailyQuestion(
        role: activeRole,
        level: user.level,
        techStack: user.techStack,
      );

      emit(
        state.copyWith(
          isLoading: false,
          user: user,
          selectedRole: activeRole,
          coachMessage: 'Ready to practice for your $activeRole interview?',
          dailyQuestion: question,
          notificationCount: 3,
          sessionSummary: SessionSummary(score: 82, streak: 5),
          popularRoles: popularRoles,
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

  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void updateTabIndex(int index) {
    emit(state.copyWith(activeTabIndex: index));
  }
}
