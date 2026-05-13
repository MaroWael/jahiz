import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:jahiz/core/constants/app_colors.dart';
import 'package:jahiz/features/paywall/models/paywall_route_arguments.dart';
import 'package:jahiz/features/paywall/presentation/screens/success_screen.dart';
import 'package:jahiz/features/paywall/services/payment_service.dart';
import 'package:jahiz/features/paywall/services/premium_firebase_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  static const String routeName = '/payment';

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const String _subscriptionCurrency = 'usd';

  final PaymentService _paymentService = PaymentService();
  final PremiumFirebaseService _premiumFirebaseService =
      PremiumFirebaseService();

  bool _isCheckingStatus = true;
  bool _isPaying = false;
  bool _isRestoring = false;
  bool _isPremium = false;
  bool _hasPendingRestore = false;
  String? _statusMessage;
  String? _currentPlanId;

  @override
  void initState() {
    super.initState();
    _loadInitialStatus();
  }

  PaywallCheckoutArguments _resolveCheckoutArguments(BuildContext context) {
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is PaywallCheckoutArguments) {
      return routeArgs;
    }
    if (routeArgs is PaywallRouteArguments) {
      return PaywallCheckoutArguments(
        paywallArgs: routeArgs,
        plan: defaultPremiumPlan(),
      );
    }

    return PaywallCheckoutArguments(
      paywallArgs: const PaywallRouteArguments(),
      plan: defaultPremiumPlan(),
    );
  }

  Future<void> _loadInitialStatus() async {
    try {
      final results = await Future.wait<Object?>([
        _premiumFirebaseService.isCurrentUserPremium(),
        _paymentService.hasPendingPremiumUnlock(),
        _premiumFirebaseService.getCurrentUserPlanId(),
      ]);

      if (!mounted) {
        return;
      }

      final isPremium = results[0] as bool? ?? false;
      final hasPendingRestore = results[1] as bool? ?? false;
      final currentPlanId = results[2] as String?;

      setState(() {
        _isCheckingStatus = false;
        _isPremium = isPremium;
        _hasPendingRestore = hasPendingRestore;
        _currentPlanId = currentPlanId;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCheckingStatus = false;
        _statusMessage =
            'Could not verify your subscription status right now. You can still continue.';
      });
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openSuccessScreen(PaywallRouteArguments args) async {
    final result = await Navigator.of(
      context,
    ).pushNamed(SuccessScreen.routeName, arguments: args);

    if (!mounted) {
      return;
    }

    if (result == true) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _handlePayNow(PaywallCheckoutArguments checkoutArgs) async {
    if (_isPaying || _isRestoring || _isCheckingStatus) {
      return;
    }

    final args = checkoutArgs.paywallArgs;
    final plan = checkoutArgs.plan;

    setState(() {
      _isPaying = true;
      _statusMessage = null;
    });

    try {
      final alreadyPremium = await _premiumFirebaseService
          .isCurrentUserPremium();
      final currentPlanId = await _premiumFirebaseService
          .getCurrentUserPlanId();
      final isUpgrade = _isUpgradePlan(plan, currentPlanId);

      if (alreadyPremium && !isUpgrade) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isPaying = false;
          _isPremium = true;
          _hasPendingRestore = false;
          _currentPlanId = currentPlanId;
        });

        _showSnackBar('You already have this plan or higher.');
        return;
      }

      final result = await _paymentService.processPremiumPayment(
        amount: plan.priceCents,
        currency: _subscriptionCurrency,
        planId: plan.id,
      );

      if (!mounted) {
        return;
      }

      if (result.isCancelled || result.isFailure) {
        setState(() {
          _isPaying = false;
        });

        _showSnackBar(result.message);
        return;
      }

      try {
        await _premiumFirebaseService.markCurrentUserPremium(planId: plan.id);
        await _paymentService.clearPendingPremiumUnlock();

        if (!mounted) {
          return;
        }

        setState(() {
          _isPaying = false;
          _isPremium = true;
          _hasPendingRestore = false;
          _currentPlanId = plan.id;
        });

        await _openSuccessScreen(args);
      } catch (_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isPaying = false;
          _hasPendingRestore = true;
          _statusMessage =
              'Payment succeeded, but Premium sync failed due to a network issue. Tap Restore Purchase to finish activation.';
        });

        _showSnackBar(
          'Payment completed, but we could not sync your Premium flag yet.',
        );
      }
    } on StateError {
      if (!mounted) {
        return;
      }

      setState(() {
        _isPaying = false;
      });

      _showSnackBar('Please sign in again to continue with payment.');
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isPaying = false;
      });

      _showSnackBar(
        error.message ??
            'Could not verify your account status in Firestore. Please try again.',
      );
    } on PaymentServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isPaying = false;
      });

      _showSnackBar(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isPaying = false;
      });

      debugPrint('Unexpected payment flow error: $error');
      _showSnackBar('Unable to complete payment: $error');
    }
  }

  Future<void> _handleRestorePurchase(
    PaywallCheckoutArguments checkoutArgs,
  ) async {
    if (_isPaying || _isRestoring) {
      return;
    }

    final args = checkoutArgs.paywallArgs;

    setState(() {
      _isRestoring = true;
      _statusMessage = null;
    });

    try {
      final isPremium = await _premiumFirebaseService.isCurrentUserPremium();
      if (isPremium) {
        await _paymentService.clearPendingPremiumUnlock();

        if (!mounted) {
          return;
        }

        setState(() {
          _isRestoring = false;
          _isPremium = true;
          _hasPendingRestore = false;
        });

        await _openSuccessScreen(args);
        return;
      }

      final hasPendingPurchase = await _paymentService
          .hasPendingPremiumUnlock();
      if (!hasPendingPurchase) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isRestoring = false;
          _hasPendingRestore = false;
        });

        _showSnackBar(
          'No pending purchase was found to restore. If you were charged, try again in a moment.',
        );
        return;
      }

      final pendingPlanId = await _paymentService.getPendingPremiumPlanId();
      final planIdToStore = (pendingPlanId == null || pendingPlanId.isEmpty)
          ? checkoutArgs.plan.id
          : pendingPlanId;

      await _premiumFirebaseService.markCurrentUserPremium(
        planId: planIdToStore,
      );
      await _paymentService.clearPendingPremiumUnlock();

      if (!mounted) {
        return;
      }

      setState(() {
        _isRestoring = false;
        _isPremium = true;
        _hasPendingRestore = false;
      });

      _showSnackBar('Premium access restored successfully.');
      await _openSuccessScreen(args);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isRestoring = false;
        _statusMessage =
            'Restore failed. Please check your connection and try again.';
      });

      _showSnackBar('Could not restore Premium right now. Please retry.');
    }
  }

  Widget _buildPlanCard(PaywallCheckoutArguments checkoutArgs) {
    final theme = Theme.of(context);
    final plan = checkoutArgs.plan;
    final args = checkoutArgs.paywallArgs;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${plan.name} Plan',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              Text(
                '\$${plan.priceUsd}.00 USD',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            plan.description,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
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
                      feature,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            args.message ??
                'Pay securely with Stripe to unlock Premium features immediately.',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    if (_statusMessage == null) {
      return const SizedBox.shrink();
    }

    final brightness = Theme.of(context).brightness;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningSurface(brightness),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warningText(brightness).withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        _statusMessage!,
        style: TextStyle(
          color: AppColors.warningText(brightness),
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }

  int _planIndex(String? planId) {
    final resolved = premiumPlanById(planId);
    final index = kPremiumPlans.indexWhere((plan) => plan.id == resolved.id);
    return index == -1 ? 0 : index;
  }

  bool _isUpgradePlan(PremiumPlan selectedPlan, String? currentPlanId) {
    if (!_isPremium) {
      return true;
    }

    final currentIndex = _planIndex(currentPlanId);
    final selectedIndex = _planIndex(selectedPlan.id);
    return selectedIndex > currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checkoutArgs = _resolveCheckoutArguments(context);
    final plan = checkoutArgs.plan;
    final currentPlan = _isPremium ? premiumPlanById(_currentPlanId) : null;
    final canUpgrade = _isUpgradePlan(plan, _currentPlanId);
    final isUpgradeBlocked = _isPremium && !canUpgrade;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Premium Checkout')),
      body: SafeArea(
        child: _isCheckingStatus
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlanCard(checkoutArgs),
                    const SizedBox(height: 14),
                    if (_isPremium) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Current plan: ${currentPlan?.name ?? 'Premium'}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isUpgradeBlocked) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Select a higher plan to upgrade your limits.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                    if (_statusMessage != null) ...[
                      _buildStatusBanner(),
                      const SizedBox(height: 14),
                    ],
                    if (_isPremium)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.successSurface(theme.brightness),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Your account is already Premium.',
                          style: TextStyle(
                            color: AppColors.successText(theme.brightness),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Need help? If your card was charged but Premium was not activated, tap Restore Purchase.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (_isPaying || _isRestoring || isUpgradeBlocked)
                      ? null
                      : () => _handlePayNow(checkoutArgs),
                  icon: _isPaying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open_rounded),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isPaying
                          ? 'Processing...'
                          : (_isPremium
                                ? 'Upgrade for \$${plan.priceUsd}.00 USD'
                                : 'Pay \$${plan.priceUsd}.00 USD'),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isPaying || _isRestoring
                      ? null
                      : () => _handleRestorePurchase(checkoutArgs),
                  icon: _isRestoring
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          color: _hasPendingRestore
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                  label: Text(
                    _isRestoring
                        ? 'Restoring...'
                        : (_hasPendingRestore
                              ? 'Restore Purchase (Recommended)'
                              : 'Restore Purchase'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
