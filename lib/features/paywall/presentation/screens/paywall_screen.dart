import 'package:flutter/material.dart';
import 'package:jahiz/features/paywall/models/paywall_route_arguments.dart';
import 'package:jahiz/features/paywall/presentation/screens/payment_screen.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  static const String routeName = '/paywall';

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  late PremiumPlan _selectedPlan;
  bool _didResolveInitialPlan = false;

  @override
  void initState() {
    super.initState();
    _selectedPlan = defaultPremiumPlan();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didResolveInitialPlan) {
      return;
    }

    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    final args = routeArgs is PaywallRouteArguments
        ? routeArgs
        : const PaywallRouteArguments();

    if (args.initialPlanId != null) {
      _selectedPlan = premiumPlanById(args.initialPlanId);
    }

    _didResolveInitialPlan = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

    final plans = kPremiumPlans;
    final selectedPlan = _selectedPlan;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                    Text(
                      'Choose your plan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...plans.map(
                      (plan) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPlanCard(
                          context,
                          plan,
                          isSelected: plan.id == selectedPlan.id,
                          onTap: () => setState(() => _selectedPlan = plan),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'What you unlock',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...highlights.map(
                      (text) => _buildHighlightTile(context, text),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'No commitment: cancel anytime from your account settings.',
                        style: TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildActions(context, args),
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

  Widget _buildPlanCard(
    BuildContext context,
    PremiumPlan plan, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFF2D4FD7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          if (plan.isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Most popular',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.description,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${plan.priceUsd}/mo',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...plan.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _buildPlanFeatureRow(context, feature),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanFeatureRow(BuildContext context, String text) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 16,
            color: Color(0xFF2D4FD7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightTile(BuildContext context, String text) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
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
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, PaywallRouteArguments args) {
    final theme = Theme.of(context);
    final selectedPlan = _selectedPlan;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
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
              onPressed: () async {
                final result = await Navigator.of(context).pushNamed(
                  PaymentScreen.routeName,
                  arguments: PaywallCheckoutArguments(
                    paywallArgs: args,
                    plan: selectedPlan,
                  ),
                );

                if (!context.mounted) {
                  return;
                }

                if (result == true) {
                  Navigator.of(context).pop(true);
                }
              },
              icon: const Icon(Icons.rocket_launch_rounded),
              label: Text('Upgrade for \$${selectedPlan.priceUsd}/mo'),
            ),
          ),
        ],
      ),
    );
  }
}
