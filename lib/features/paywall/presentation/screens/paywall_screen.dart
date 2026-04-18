import 'package:flutter/material.dart';
import 'package:jahiz/features/paywall/models/paywall_route_arguments.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  static const String routeName = '/paywall';

  @override
  Widget build(BuildContext context) {
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    final args = routeArgs is PaywallRouteArguments
        ? routeArgs
        : const PaywallRouteArguments();

    final message =
        (args.message ??
                '${args.featureName} is available for Premium users only. Upgrade to continue.')
            .trim();

    final highlights = args.featureHighlights.isEmpty
        ? const <String>[
            'Unlimited mock interviews across roles and levels',
            'Detailed AI feedback with stronger model answers',
            'Advanced progress reports and weak-area insights',
          ]
        : args.featureHighlights;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(args: args, message: message),
                    const SizedBox(height: 18),
                    _buildPlanCard(),
                    const SizedBox(height: 18),
                    Text(
                      'What you unlock',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF20263A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...highlights.map(_buildHighlightTile),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF0FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'No commitment: cancel anytime from your account settings.',
                        style: TextStyle(
                          color: Color(0xFF30436D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHero({
    required PaywallRouteArguments args,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D4FD7), Color(0xFF5A68FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            args.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFFE6EBFF),
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE3F7)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt_rounded, color: Color(0xFFCE8A00)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Plan',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                SizedBox(height: 2),
                Text(
                  'Best for interview-focused weekly practice',
                  style: TextStyle(color: Color(0xFF5F6B89), height: 1.25),
                ),
              ],
            ),
          ),
          const Text(
            '4.99\$/mo',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF1E2C4F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightTile(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFFE5ECFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 18,
              color: Color(0xFF2D4FD7),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF253251),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Maybe later'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Upgrade flow will be connected soon.'),
                  ),
                );
              },
              icon: const Icon(Icons.rocket_launch_rounded),
              label: const Text('Upgrade now'),
            ),
          ),
        ],
      ),
    );
  }
}
