import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jahiz/core/constants/app_colors.dart';

class OnboardingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;

  const OnboardingItem({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing icon circle
          Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withAlpha(50),
                  border: Border.all(
                    color: accentColor.withAlpha(100),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withAlpha(80),
                      blurRadius: 48,
                      spreadRadius: 12,
                    ),
                  ],
                ),
                child: Icon(icon, size: 88, color: Colors.white),
              )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.6, 0.6),
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),

          const SizedBox(height: 52),

          // Title
          Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(
                begin: 0.3,
                end: 0,
                delay: 200.ms,
                duration: 400.ms,
                curve: Curves.easeOut,
              ),

          const SizedBox(height: 20),

          // Description
          Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              )
              .animate()
              .fadeIn(delay: 350.ms, duration: 400.ms)
              .slideY(
                begin: 0.3,
                end: 0,
                delay: 350.ms,
                duration: 400.ms,
                curve: Curves.easeOut,
              ),
        ],
      ),
    );
  }
}
