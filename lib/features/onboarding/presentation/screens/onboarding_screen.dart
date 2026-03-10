import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:jahiz/core/constants/app_colors.dart';
import 'package:jahiz/features/home/presentation/screens/home_screan.dart';
import '../cubit/onboarding_cubit.dart';
import '../widgets/onboarding_item.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _controller;

  static const List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.waving_hand_rounded,
      'title': 'Welcome to Jahiz',
      'description':
          'Your AI-powered interview coach that helps you land your dream job.',
      'color': AppColors.onboarding1,
    },
    {
      'icon': Icons.psychology_rounded,
      'title': 'AI Interview Practice',
      'description':
          'Get realistic interview questions tailored to your field and experience level.',
      'color': AppColors.onboarding2,
    },
    {
      'icon': Icons.trending_up_rounded,
      'title': 'Track Your Progress',
      'description':
          'See detailed feedback and monitor your improvement over time.',
      'color': AppColors.onboarding3,
    },
    {
      'icon': Icons.rocket_launch_rounded,
      'title': 'Get Started',
      'description':
          'Begin your interview preparation journey today and ace your next interview!',
      'color': AppColors.onboarding4,
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (_) => const HomeScrean()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: BlocListener<OnboardingCubit, int>(
              listener: (context, page) {
                _controller.animateToPage(
                  page,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              },
              child: SafeArea(
                child: Column(
                  children: [
                    // Skip button row
                    BlocBuilder<OnboardingCubit, int>(
                      builder: (context, page) {
                        final isLast = page == _pages.length - 1;
                        return SizedBox(
                          height: 48,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: isLast
                                  ? const SizedBox.shrink()
                                  : TextButton(
                                      onPressed: () => _navigateToHome(context),
                                      child: const Text(
                                        'Skip',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Page view
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: _pages.length,
                        onPageChanged: (index) =>
                            context.read<OnboardingCubit>().changePage(index),
                        itemBuilder: (context, index) {
                          final page = _pages[index];
                          return OnboardingItem(
                            icon: page['icon'] as IconData,
                            title: page['title'] as String,
                            description: page['description'] as String,
                            accentColor: page['color'] as Color,
                          );
                        },
                      ),
                    ),

                    // Bottom: dots + button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                      child: BlocBuilder<OnboardingCubit, int>(
                        builder: (context, page) {
                          final isLast = page == _pages.length - 1;
                          return Column(
                            children: [
                              // Page indicator dots
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  _pages.length,
                                  (i) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: i == page ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: i == page
                                          ? AppColors.primary
                                          : const Color(0xFFD1C4E9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Next / Get Started button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (isLast) {
                                      _navigateToHome(context);
                                    } else {
                                      context.read<OnboardingCubit>().nextPage(
                                        _pages.length,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    isLast ? 'Get Started' : 'Next',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
