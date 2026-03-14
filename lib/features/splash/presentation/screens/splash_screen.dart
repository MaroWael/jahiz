import 'dart:math' as math show cos, pi, sin;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jahiz/core/services/user_profile_service.dart';
import 'package:jahiz/features/auth/presentation/screens/auth_screen.dart';
import 'package:jahiz/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:jahiz/features/home/presentation/screens/home_screan.dart';
import 'package:jahiz/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:jahiz/features/profile_onboarding/presentation/screens/profile_onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _seenOnboardingKey = 'seen_onboarding';
  final UserProfileService _userProfileService = UserProfileService();

  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _rotationAnimation;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _taglineOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
      ),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    _rotationAnimation = Tween<double>(begin: -0.14, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.15, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _slideAnimation = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _glowAnimation = Tween<double>(begin: 0.72, end: 1.22).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );
    _taglineOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.55, 0.95, curve: Curves.easeIn),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    _animationController.forward();
    _goNext();
  }

  Future<void> _goNext() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool(_seenOnboardingKey) ?? false;
    final currentUser = FirebaseAuth.instance.currentUser;

    Widget destination = const OnboardingScreen();

    if (seenOnboarding) {
      if (currentUser == null) {
        destination = const AuthScreen();
      } else if (!currentUser.emailVerified &&
          currentUser.providerData.any(
            (provider) => provider.providerId == 'password',
          )) {
        destination = const EmailVerificationScreen();
      } else {
        final hasCompleted = await _userProfileService.hasCompletedOnboarding(
          currentUser.uid,
        );
        destination = hasCompleted
            ? const HomeScrean()
            : const ProfileOnboardingScreen();
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 2600));
    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (_) => destination),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF2A0F54),
      body: Stack(
        children: [
          Positioned(
            top: -size.height * 0.15,
            right: -size.width * 0.2,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.9 + (_animationController.value * 0.2),
                  child: Container(
                    width: size.width * 0.8,
                    height: size.width * 0.8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF3E1A74),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -size.height * 0.12,
            left: -size.width * 0.24,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 - (_animationController.value * 0.1),
                  child: Container(
                    width: size.width * 0.9,
                    height: size.width * 0.9,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF341566),
                    ),
                  ),
                );
              },
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Transform.rotate(
                        angle: _rotationAnimation.value * math.pi,
                        child: Image.asset(
                          'assets/splash-screan-icon/icon-jahiz.png',
                          width: size.width * 0.42,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return IgnorePointer(
                  child: Opacity(
                    opacity: (_glowAnimation.value - 0.72).clamp(0.0, 1.0),
                    child: Container(
                      width: size.width * 0.56,
                      height: size.width * 0.56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF9A7BFF,
                            ).withValues(alpha: 0.32),
                            blurRadius: 40 * _glowAnimation.value,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final angle = _animationController.value * 2 * math.pi;
                final radius = size.width * 0.28;
                return Stack(
                  children: [
                    Positioned(
                      left: size.width / 2 + (radius * math.cos(angle)) - 5,
                      top: size.height / 2 + (radius * math.sin(angle)) - 5,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0x66FFFFFF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left:
                          size.width / 2 +
                          (radius * math.cos(angle + math.pi)) -
                          3,
                      top:
                          size.height / 2 +
                          (radius * math.sin(angle + math.pi)) -
                          3,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0x55FFFFFF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.66),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _taglineOpacityAnimation.value,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      (1 - _taglineOpacityAnimation.value) * 10,
                    ),
                    child: const Text(
                      'prepare. practice. perform.',
                      style: TextStyle(
                        color: Color(0xDDFFFFFF),
                        fontSize: 16,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
