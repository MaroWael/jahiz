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
  });

  final String title;
  final String? message;
  final String featureName;
  final List<String> featureHighlights;
}
