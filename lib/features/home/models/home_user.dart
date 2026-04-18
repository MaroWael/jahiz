class HomeUser {
  HomeUser({
    required this.name,
    required this.role,
    required this.level,
    required this.techStack,
    this.isPremium = false,
  });

  final String name;
  final String role;
  final String level;
  final List<String> techStack;
  final bool isPremium;
}
