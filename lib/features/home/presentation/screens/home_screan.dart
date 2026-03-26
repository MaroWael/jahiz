import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jahiz/features/home/presentation/cubit/home_cubit.dart';
import 'package:jahiz/features/home/presentation/cubit/home_state.dart';

class HomeScrean extends StatefulWidget {
  const HomeScrean({super.key});

  @override
  State<HomeScrean> createState() => _HomeScreanState();
}

class _HomeScreanState extends State<HomeScrean> {
  final HomeCubit _homeCubit = HomeCubit();

  @override
  void initState() {
    super.initState();
    _homeCubit.initialize();
  }

  @override
  void dispose() {
    _homeCubit.close();
    super.dispose();
  }

  void _openPractice() {
    Navigator.pushNamed(context, '/practice');
  }

  void _openAnswer() {
    Navigator.pushNamed(context, '/answer');
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
          const Text(
            'Your Career Target',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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

  Widget _buildRoleCard(String role, bool selected) {
    return GestureDetector(
      onTap: () => _homeCubit.selectRole(role),
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE6EEFF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF3A7BFF) : const Color(0xFFE6E8EC),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.work_outline_rounded,
              color: selected ? const Color(0xFF3A7BFF) : Colors.black87,
            ),
            const SizedBox(height: 10),
            Text(role, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                  'Last Session',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text('Score: ${summary.score}%'),
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
                onRefresh: _homeCubit.initialize,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeader(state),
                    const SizedBox(height: 16),
                    _buildCoachCard(state),
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
