class PaywallRouteArguments {
  const PaywallRouteArguments({
    this.title = 'Unlock Premium',
    this.message,
    this.featureName = 'Premium content',
    this.featureHighlights = const <String>[
      'Unlimited mock interviews across roles and levels',
      'Detailed AI feedback with stronger model answers',
      'Advanced progress reports and weak-area insights',
    ],
    this.initialPlanId,
  });

  final String title;
  final String? message;
  final String featureName;
  final List<String> featureHighlights;
  final String? initialPlanId;
}

class PremiumPlan {
  const PremiumPlan({
    required this.id,
    required this.name,
    required this.priceUsd,
    required this.priceCents,
    required this.description,
    required this.questionsPerSession,
    required this.dailyPracticeLimit,
    required this.features,
    this.isPopular = false,
  });

  final String id;
  final String name;
  final int priceUsd;
  final int priceCents;
  final String description;
  final int questionsPerSession;
  final int? dailyPracticeLimit;
  final List<String> features;
  final bool isPopular;

  bool get hasUnlimitedPractice => dailyPracticeLimit == null;
}

const List<PremiumPlan> kPremiumPlans = <PremiumPlan>[
  PremiumPlan(
    id: 'starter',
    name: 'Starter',
    priceUsd: 5,
    priceCents: 500,
    description: 'Light weekly practice plan',
    questionsPerSession: 5,
    dailyPracticeLimit: 5,
    features: <String>[
      '5 questions per practice session',
      'Up to 5 practice sessions per day',
      'Basic progress reports',
    ],
  ),
  PremiumPlan(
    id: 'pro',
    name: 'Pro',
    priceUsd: 10,
    priceCents: 1000,
    description: 'Most popular for steady growth',
    questionsPerSession: 8,
    dailyPracticeLimit: 10,
    features: <String>[
      '8 questions per practice session',
      'Up to 10 practice sessions per day',
      'Advanced reports and weak areas',
    ],
    isPopular: true,
  ),
  PremiumPlan(
    id: 'elite',
    name: 'Elite',
    priceUsd: 20,
    priceCents: 2000,
    description: 'Best for intense interview prep',
    questionsPerSession: 15,
    dailyPracticeLimit: null,
    features: <String>[
      '15 questions per practice session',
      'Unlimited practice sessions',
      'Priority support',
    ],
  ),
];

PremiumPlan defaultPremiumPlan() {
  return kPremiumPlans.firstWhere(
    (plan) => plan.isPopular,
    orElse: () => kPremiumPlans.first,
  );
}

PremiumPlan premiumPlanById(String? id) {
  if (id == null || id.trim().isEmpty) {
    return defaultPremiumPlan();
  }

  final normalized = id.trim().toLowerCase();
  return kPremiumPlans.firstWhere(
    (plan) => plan.id.toLowerCase() == normalized,
    orElse: () => defaultPremiumPlan(),
  );
}

class PaywallCheckoutArguments {
  const PaywallCheckoutArguments({
    required this.paywallArgs,
    required this.plan,
  });

  final PaywallRouteArguments paywallArgs;
  final PremiumPlan plan;
}
