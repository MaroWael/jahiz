import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
  static const int _subscriptionAmount = 5000;
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

  @override
  void initState() {
    super.initState();
    _loadInitialStatus();
  }

  PaywallRouteArguments _resolveArguments(BuildContext context) {
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is PaywallRouteArguments) {
      return routeArgs;
    }

    return const PaywallRouteArguments();
  }

  Future<void> _loadInitialStatus() async {
    try {
      final status = await Future.wait<bool>([
        _premiumFirebaseService.isCurrentUserPremium(),
        _paymentService.hasPendingPremiumUnlock(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _isCheckingStatus = false;
        _isPremium = status[0];
        _hasPendingRestore = status[1];
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

  Future<void> _handlePayNow(PaywallRouteArguments args) async {
    if (_isPaying || _isRestoring || _isCheckingStatus) {
      return;
    }

    setState(() {
      _isPaying = true;
      _statusMessage = null;
    });

    try {
      final alreadyPremium = await _premiumFirebaseService
          .isCurrentUserPremium();
      if (alreadyPremium) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isPaying = false;
          _isPremium = true;
          _hasPendingRestore = false;
        });

        _showSnackBar('You already have Premium access.');
        return;
      }

      final result = await _paymentService.processPremiumPayment(
        amount: _subscriptionAmount,
        currency: _subscriptionCurrency,
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
        await _premiumFirebaseService.markCurrentUserPremium();
        await _paymentService.clearPendingPremiumUnlock();

        if (!mounted) {
          return;
        }

        setState(() {
          _isPaying = false;
          _isPremium = true;
          _hasPendingRestore = false;
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

  Future<void> _handleRestorePurchase(PaywallRouteArguments args) async {
    if (_isPaying || _isRestoring) {
      return;
    }

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

      await _premiumFirebaseService.markCurrentUserPremium();
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

  Widget _buildPlanCard(PaywallRouteArguments args) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDEE3F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Premium Subscription',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Color(0xFF1D2744),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Amount: 50.00 USD',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF354268),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            args.message ??
                'Pay securely with Stripe to unlock Premium features immediately.',
            style: const TextStyle(
              color: Color(0xFF5B6581),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE69C)),
      ),
      child: Text(
        _statusMessage!,
        style: const TextStyle(
          color: Color(0xFF6E5600),
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = _resolveArguments(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(title: const Text('Premium Checkout')),
      body: SafeArea(
        child: _isCheckingStatus
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlanCard(args),
                    const SizedBox(height: 14),
                    if (_statusMessage != null) ...[
                      _buildStatusBanner(),
                      const SizedBox(height: 14),
                    ],
                    if (_isPremium)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F6EE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Your account is already Premium.',
                          style: TextStyle(
                            color: Color(0xFF1D6B44),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Need help? If your card was charged but Premium was not activated, tap Restore Purchase.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
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
                  onPressed: (_isPaying || _isRestoring || _isPremium)
                      ? null
                      : () => _handlePayNow(args),
                  icon: _isPaying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open_rounded),
                  label: Text(_isPaying ? 'Processing...' : 'Pay 50.00 USD'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isPaying || _isRestoring
                      ? null
                      : () => _handleRestorePurchase(args),
                  icon: _isRestoring
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          color: _hasPendingRestore
                              ? const Color(0xFF2D4FD7)
                              : Colors.grey.shade700,
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
