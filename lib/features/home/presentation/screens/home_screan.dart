import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jahiz/features/auth/presentation/screens/auth_screen.dart';
import 'package:jahiz/features/home/presentation/cubit/home_cubit.dart';
import 'package:jahiz/features/home/presentation/cubit/home_state.dart';
import 'package:jahiz/features/home/services/local_storage_service.dart';

class HomeScrean extends StatefulWidget {
  const HomeScrean({super.key});

  @override
  State<HomeScrean> createState() => _HomeScreanState();
}

class _HomeScreanState extends State<HomeScrean> {
  final HomeCubit _homeCubit = HomeCubit();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _homeCubit.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _homeCubit.close();
    super.dispose();
  }

  Future<void> _refreshHome() async {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    await _homeCubit.initialize();
  }

  Future<void> _openPractice() async {
    await Navigator.pushNamed(context, '/practice');
    if (!mounted) {
      return;
    }
    await _homeCubit.initialize();
  }

  Future<void> _openAnswer() async {
    await Navigator.pushNamed(context, '/answer');
    if (!mounted) {
      return;
    }
    await _homeCubit.initialize();
  }

  void _openReports() {
    Navigator.pushNamed(context, '/reports');
  }

  Future<void> _openProfile() async {
    final result = await Navigator.pushNamed(context, '/profile');
    if (!mounted) {
      return;
    }

    if (result == true) {
      await _homeCubit.initialize();
    }
  }

  Future<void> _logout() async {
    final didSignOut = await _homeCubit.signOut();
    if (!didSignOut || !mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  Widget _buildHeader(HomeState state) {
    final userName = state.user?.name ?? 'User';
    return Row(
      children: [
        Expanded(
          child: Text(
            'Welcome back, $userName 👋',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded, size: 28),
            ),
            if (state.notificationCount > 0)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    state.notificationCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          tooltip: 'Logout',
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    );
  }

  Widget _buildCoachCard(HomeState state) {
    return InkWell(
      onTap: _openPractice,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6048FF), Color(0xFF3A7BFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your AI Interview Coach',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.coachMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeQuotaHint(HomeState state) {
    final user = state.user;
    if (user == null) {
      return const SizedBox.shrink();
    }

    if (user.isPremium) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F6EE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Premium account: unlimited practice sessions today.',
          style: TextStyle(
            color: Color(0xFF1D6B44),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final remaining = state.freePracticeSessionsLeft ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Free practice sessions left today: $remaining/${LocalStorageService.freeDailyPracticeSessionLimit}',
        style: const TextStyle(
          color: Color(0xFF8B4A00),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProfileSummary(HomeState state) {
    final user = state.user;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your Career Target',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              TextButton.icon(
                onPressed: _openProfile,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Role: ${user.role}'),
          Text('Level: ${user.level}'),
          Text('Tech Stack: ${user.techStack.join(', ')}'),
        ],
      ),
    );
  }

  Widget _buildSearchBar(HomeState state) {
    return TextField(
      controller: _searchController,
      onChanged: _homeCubit.updateSearchQuery,
      decoration: InputDecoration(
        hintText: 'Search job roles...',
        prefixIcon: const Icon(Icons.search),
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildRoleCard(String role, bool selected, int index) {
    final List<Color> cardColors = [
      const Color(0xFF4A7DFF),
      const Color(0xFF2EC5B6),
      const Color(0xFF6C63FF),
      const Color(0xFFFF8C42),
    ];

    final Color currentColor = cardColors[index % cardColors.length];

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _homeCubit.selectRole(role);
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? currentColor : currentColor.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.white : currentColor,
            width: selected ? 2 : 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  role,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyQuestion(HomeState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Question",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
            state.dailyQuestion.isEmpty
                ? 'Loading your daily practice question...'
                : state.dailyQuestion,
            style: const TextStyle(height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _openAnswer,
              child: const Text('Answer Now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionSummary(HomeState state) {
    final summary = state.sessionSummary;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall Progress',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text('Average Score: ${summary.score}%'),
                Text('Streak: ${summary.streak} days'),
              ],
            ),
          ),
          const Icon(Icons.local_fire_department_rounded, color: Colors.orange),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeCubit>.value(
      value: _homeCubit,
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFFF4F6FB),
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: _refreshHome,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeader(state),
                    const SizedBox(height: 16),
                    _buildCoachCard(state),
                    const SizedBox(height: 10),
                    _buildPracticeQuotaHint(state),
                    const SizedBox(height: 16),
                    _buildProfileSummary(state),
                    const SizedBox(height: 16),
                    _buildSearchBar(state),
                    const SizedBox(height: 16),
                    const Text(
                      'Popular Job Roles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: state.filteredRoles
                            .map(
                              (role) => _buildRoleCard(
                                role,
                                state.selectedRole == role,
                                state.filteredRoles.indexOf(role),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDailyQuestion(state),
                    const SizedBox(height: 16),
                    _buildSessionSummary(state),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        state.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    if (state.isLoading) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: state.activeTabIndex,
              onTap: (index) {
                _homeCubit.updateTabIndex(index);
                if (index == 1) {
                  _openPractice();
                } else if (index == 2) {
                  _openReports();
                } else if (index == 3) {
                  _openProfile();
                }
              },
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.record_voice_over_outlined),
                  activeIcon: Icon(Icons.record_voice_over_rounded),
                  label: 'Practice',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.show_chart_outlined),
                  activeIcon: Icon(Icons.show_chart_rounded),
                  label: 'Progress',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
