import 'package:jahiz/features/home/models/home_user.dart';
import 'package:jahiz/features/home/models/session_summary.dart';

class HomeState {
  const HomeState({
    this.isLoading = false,
    this.user,
    this.coachMessage = '',
    this.dailyQuestion = '',
    this.errorMessage,
    this.selectedRole,
    this.searchQuery = '',
    this.notificationCount = 0,
    this.sessionSummary,
    this.activeTabIndex = 0,
    this.popularRoles = const <String>[],
  });

  final bool isLoading;
  final HomeUser? user;
  final String coachMessage;
  final String dailyQuestion;
  final String? errorMessage;
  final String? selectedRole;
  final String searchQuery;
  final int notificationCount;
  final SessionSummary? sessionSummary;
  final int activeTabIndex;
  final List<String> popularRoles;

  List<String> get filteredRoles {
    final source = popularRoles;
    if (searchQuery.trim().isEmpty) {
      return source;
    }

    return source
        .where((role) => role.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  HomeState copyWith({
    bool? isLoading,
    HomeUser? user,
    String? coachMessage,
    String? dailyQuestion,
    String? errorMessage,
    String? selectedRole,
    String? searchQuery,
    int? notificationCount,
    SessionSummary? sessionSummary,
    int? activeTabIndex,
    List<String>? popularRoles,
    bool clearError = false,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      coachMessage: coachMessage ?? this.coachMessage,
      dailyQuestion: dailyQuestion ?? this.dailyQuestion,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedRole: selectedRole ?? this.selectedRole,
      searchQuery: searchQuery ?? this.searchQuery,
      notificationCount: notificationCount ?? this.notificationCount,
      sessionSummary: sessionSummary ?? this.sessionSummary,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      popularRoles: popularRoles ?? this.popularRoles,
    );
  }
}
