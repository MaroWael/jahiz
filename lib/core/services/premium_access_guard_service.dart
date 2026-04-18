enum PremiumFeature { practiceInterview, aiEvaluation, advancedReports }

extension PremiumFeatureLabel on PremiumFeature {
  String get label {
    switch (this) {
      case PremiumFeature.practiceInterview:
        return 'Practice interview';
      case PremiumFeature.aiEvaluation:
        return 'AI evaluation';
      case PremiumFeature.advancedReports:
        return 'Advanced reports';
    }
  }
}

enum PremiumDeniedHandling { returnError, triggerPaywall }

class PremiumAccessDecision {
  const PremiumAccessDecision._({
    required this.isAllowed,
    required this.shouldTriggerPaywall,
    this.message,
  });

  const PremiumAccessDecision.allowed()
    : this._(isAllowed: true, shouldTriggerPaywall: false);

  const PremiumAccessDecision.deniedWithError({required String message})
    : this._(isAllowed: false, shouldTriggerPaywall: false, message: message);

  const PremiumAccessDecision.deniedWithPaywall({required String message})
    : this._(isAllowed: false, shouldTriggerPaywall: true, message: message);

  final bool isAllowed;
  final bool shouldTriggerPaywall;
  final String? message;
}

class PremiumAccessGuardService {
  const PremiumAccessGuardService();

  PremiumAccessDecision checkAccess({
    required bool? isPremium,
    required PremiumFeature feature,
    PremiumDeniedHandling deniedHandling = PremiumDeniedHandling.returnError,
  }) {
    if (isPremium == true) {
      return const PremiumAccessDecision.allowed();
    }

    final message =
        '${feature.label} is available for Premium users only. Upgrade to continue.';

    if (deniedHandling == PremiumDeniedHandling.triggerPaywall) {
      return PremiumAccessDecision.deniedWithPaywall(message: message);
    }

    return PremiumAccessDecision.deniedWithError(message: message);
  }
}
