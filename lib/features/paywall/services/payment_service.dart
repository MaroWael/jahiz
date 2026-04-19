import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart'
    show MissingPluginException, PlatformException;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum PaymentStatus { success, cancelled, failed }

class PaymentResult {
  const PaymentResult._({
    required this.status,
    required this.message,
    this.clientSecret,
  });

  const PaymentResult.success({required String clientSecret})
    : this._(
        status: PaymentStatus.success,
        message: 'Payment completed successfully.',
        clientSecret: clientSecret,
      );

  const PaymentResult.cancelled({required String message})
    : this._(status: PaymentStatus.cancelled, message: message);

  const PaymentResult.failed({required String message})
    : this._(status: PaymentStatus.failed, message: message);

  final PaymentStatus status;
  final String message;
  final String? clientSecret;

  bool get isSuccess => status == PaymentStatus.success;
  bool get isCancelled => status == PaymentStatus.cancelled;
  bool get isFailure => status == PaymentStatus.failed;
}

class PaymentServiceException implements Exception {
  const PaymentServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PaymentService {
  PaymentService({
    http.Client? httpClient,
    String? paymentEndpoint,
    String? stripePublishableKey,
  }) : _httpClient = httpClient ?? http.Client(),
       _paymentEndpoint =
           paymentEndpoint ??
           'https://stripe-server-45jm18xk1-abdelrahmansaid00s-projects.vercel.app/api/payment',
       _stripePublishableKey =
           (stripePublishableKey ?? dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '')
               .trim();

  final http.Client _httpClient;
  final String _paymentEndpoint;
  final String _stripePublishableKey;

  static const String _pendingPremiumUnlockKey =
      'pending_premium_unlock_after_stripe';

  Future<PaymentResult> processPremiumPayment({
    required int amount,
    required String currency,
    String merchantDisplayName = 'Jahiz Premium',
  }) async {
    if (amount <= 0) {
      throw const PaymentServiceException(
        'Payment amount must be greater than 0.',
      );
    }

    final normalizedCurrency = currency.trim().toLowerCase();
    if (normalizedCurrency.isEmpty) {
      throw const PaymentServiceException('Payment currency is required.');
    }

    _ensureSupportedPlatform();
    try {
      await _configureStripe();
    } on PaymentServiceException {
      rethrow;
    } on PlatformException catch (error) {
      throw PaymentServiceException(
        error.message ??
            'Stripe configuration failed. Please check your publishable key.',
      );
    } on MissingPluginException {
      throw const PaymentServiceException(
        'Stripe SDK is not available on this build. Run a full rebuild and try again.',
      );
    } catch (_) {
      throw const PaymentServiceException(
        'Stripe initialization failed. Please try again.',
      );
    }
    late final String clientSecret;
    try {
      clientSecret = await _createPaymentIntent(
        amount: amount,
        currency: normalizedCurrency,
      );
    } on PaymentServiceException {
      rethrow;
    } on TimeoutException {
      throw const PaymentServiceException(
        'Payment request timed out. Please check your internet and try again.',
      );
    } on http.ClientException {
      throw const PaymentServiceException(
        'Could not reach the payment server. Please check your internet and try again.',
      );
    } catch (_) {
      throw const PaymentServiceException(
        'Unable to create payment request. Please try again.',
      );
    }

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: merchantDisplayName,
          style: ThemeMode.system,
          allowsDelayedPaymentMethods: false,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // Persist a local reconciliation marker before Firestore sync.
      await markPendingPremiumUnlock();

      return PaymentResult.success(clientSecret: clientSecret);
    } on StripeException catch (error) {
      if (error.error.code == FailureCode.Canceled) {
        return const PaymentResult.cancelled(
          message: 'Payment was cancelled before completion.',
        );
      }

      return PaymentResult.failed(
        message:
            error.error.localizedMessage ??
            'Stripe could not complete your payment.',
      );
    } on PlatformException catch (error) {
      return PaymentResult.failed(
        message:
            error.message ??
            'Stripe platform error occurred. Please try again.',
      );
    } catch (_) {
      return const PaymentResult.failed(
        message:
            'Something went wrong while opening the payment sheet. Please try again.',
      );
    }
  }

  Future<void> _configureStripe() async {
    if (_stripePublishableKey.isEmpty) {
      throw const PaymentServiceException(
        'Stripe is not configured. Add STRIPE_PUBLISHABLE_KEY to .env.',
      );
    }

    Stripe.publishableKey = _stripePublishableKey;
    await Stripe.instance.applySettings();
  }

  void _ensureSupportedPlatform() {
    if (kIsWeb) {
      throw const PaymentServiceException(
        'Stripe Payment Sheet is available only on Android and iOS in this app.',
      );
    }

    final platform = defaultTargetPlatform;
    if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
      throw const PaymentServiceException(
        'Stripe Payment Sheet is available only on Android and iOS in this app.',
      );
    }
  }

  Future<String> _createPaymentIntent({
    required int amount,
    required String currency,
  }) async {
    final uri = Uri.parse(_paymentEndpoint);

    final response = await _httpClient
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'amount': amount, 'currency': currency}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaymentServiceException(
        'Payment server error (${response.statusCode}). Please try again.',
      );
    }

    final body = response.body.trim();
    if (body.isEmpty) {
      throw const PaymentServiceException(
        'Payment server returned an empty response.',
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const PaymentServiceException('Invalid payment response format.');
    }

    final clientSecret = (decoded['client_secret'] as String? ?? '').trim();
    if (clientSecret.isEmpty) {
      throw const PaymentServiceException(
        'Payment response is missing the client secret.',
      );
    }

    return clientSecret;
  }

  Future<void> markPendingPremiumUnlock() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_pendingPremiumUnlockKey, true);
  }

  Future<void> clearPendingPremiumUnlock() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_pendingPremiumUnlockKey);
  }

  Future<bool> hasPendingPremiumUnlock() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_pendingPremiumUnlockKey) ?? false;
  }
}
