import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jahiz/core/constants/app_colors.dart';
import 'package:jahiz/core/services/theme_controller.dart';
import 'package:jahiz/features/home/models/practice_session_record.dart';
import 'package:jahiz/features/paywall/models/paywall_route_arguments.dart';
import 'package:jahiz/features/paywall/presentation/screens/paywall_screen.dart';
import 'package:jahiz/features/paywall/services/payment_service.dart';
import 'package:jahiz/features/profile_management/presentation/controllers/profile_management_controller.dart';

class _PremiumBadgeStyle {
  const _PremiumBadgeStyle({
    required this.backgroundColor,
    required this.textColor,
  });

  final Color backgroundColor;
  final Color textColor;
}

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  State<ProfileManagementScreen> createState() =>
      _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  static const List<String> _levelOptions = <String>['junior', 'mid', 'senior'];
  static const int _activityWeeks = 12;

  final ProfileManagementController _controller = ProfileManagementController();
  final PaymentService _paymentService = PaymentService();
  final AppThemeController _themeController = AppThemeController.instance;
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _stackController = TextEditingController();

  String _name = 'User';
  String _email = '';
  bool _isPremium = false;
  String? _premiumPlanId;

  String _savedRole = '';
  String _savedLevel = '';
  List<String> _savedTechStack = <String>[];

  String? _selectedLevel;
  List<String> _techStack = <String>[];

  List<DateTime> _interviewDates = <DateTime>[];
  int _completedInterviews = 0;
  double? _averageScorePercent;
  int _activeDays = 0;
  int _currentStreak = 0;
  int _bestDayCount = 0;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _isCancellingPremium = false;

  bool get _isFormValid {
    return _roleController.text.trim().isNotEmpty &&
        (_selectedLevel?.trim().isNotEmpty ?? false) &&
        _techStack.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _loadScreenData();
  }

  @override
  void dispose() {
    _roleController.dispose();
    _stackController.dispose();
    super.dispose();
  }

  Future<void> _loadScreenData() async {
    try {
      final results = await Future.wait<Object>([
        _controller.loadCurrentProfile(),
        _controller.loadCompletedSessions(),
      ]);

      final profile = results[0] as ProfileManagementData;
      final sessions = results[1] as List<PracticeSessionRecord>;

      final now = DateTime.now();
      final endDate = DateTime(now.year, now.month, now.day);
      final startDate = endDate.subtract(
        const Duration(days: _activityWeeks * 7 - 1),
      );

      final interviewDates = sessions
          .map((session) => session.date)
          .whereType<DateTime>()
          .toList();

      final activityMap = _buildActivityMap(
        interviewDates: interviewDates,
        startDate: startDate,
        endDate: endDate,
      );

      final averageScore = sessions.isEmpty
          ? null
          : sessions.fold<double>(
                  0,
                  (total, session) => total + session.scorePercent,
                ) /
                sessions.length;

      if (!mounted) {
        return;
      }

      setState(() {
        _name = profile.name;
        _email = profile.email;
        _isPremium = profile.isPremium;
        _premiumPlanId = profile.premiumPlanId;

        _savedRole = profile.role;
        _savedLevel = _normalizeLevel(profile.level);
        _savedTechStack = List<String>.from(profile.techStack);
        _syncFormWithSavedProfile();

        _interviewDates = interviewDates;
        _completedInterviews = sessions.length;
        _averageScorePercent = averageScore;
        _activeDays = activityMap.values.where((value) => value > 0).length;
        _currentStreak = _calculateCurrentStreak(activityMap, endDate);
        _bestDayCount = activityMap.values.isEmpty
            ? 0
            : activityMap.values.fold<int>(0, math.max);

        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
      _showSnackBar('Unable to load profile data.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isNetworkSyncFailure(Object error) {
    if (error is FirebaseException) {
      const connectivityCodes = <String>{
        'unavailable',
        'network-request-failed',
        'deadline-exceeded',
      };
      return connectivityCodes.contains(error.code);
    }

    return false;
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (!_isFormValid || _selectedLevel == null) {
      _showSnackBar('Role, level, and tech stack are required.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _controller.updateProfile(
        role: _roleController.text.trim(),
        level: _selectedLevel!,
        techStack: _techStack,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _savedRole = _roleController.text.trim();
        _savedLevel = _selectedLevel!.trim();
        _savedTechStack = List<String>.from(_techStack);
        _isEditing = false;
      });

      _showSnackBar('Profile updated successfully.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      if (_isNetworkSyncFailure(error)) {
        _showSnackBar('Check your internet connection');
      } else {
        _showSnackBar('Failed to update profile. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _confirmCancelPremium() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Premium subscription?'),
          content: const Text(
            'Your Premium access will end immediately, and premium-only '
            'features will be locked. You can upgrade again anytime.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep Premium'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Cancel Premium'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _handleCancelPremium() async {
    if (_isCancellingPremium) {
      return;
    }

    if (!_isPremium) {
      _showSnackBar('You do not have an active Premium subscription.');
      return;
    }

    final confirmed = await _confirmCancelPremium();
    if (!confirmed) {
      return;
    }

    setState(() => _isCancellingPremium = true);

    try {
      final cancelled = await _controller.cancelPremiumSubscription();
      if (!cancelled) {
        if (!mounted) {
          return;
        }

        setState(() => _isCancellingPremium = false);
        _showSnackBar('Premium is already inactive for this account.');
        return;
      }

      try {
        await _paymentService.clearPendingPremiumUnlock();
      } catch (_) {
        // Local cleanup failure should not block premium cancellation.
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isCancellingPremium = false;
        _isPremium = false;
      });

      _showSnackBar('Premium subscription cancelled.');
    } on StateError {
      if (!mounted) {
        return;
      }

      setState(() => _isCancellingPremium = false);
      _showSnackBar('Please sign in again to manage your subscription.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isCancellingPremium = false);
      if (_isNetworkSyncFailure(error)) {
        _showSnackBar('Check your internet connection');
      } else {
        _showSnackBar('Failed to cancel Premium. Please try again.');
      }
    }
  }

  void _syncFormWithSavedProfile() {
    _roleController.text = _savedRole;
    _selectedLevel = _savedLevel.isEmpty ? null : _savedLevel;
    _techStack = List<String>.from(_savedTechStack);
  }

  void _startEditing() {
    setState(() {
      _syncFormWithSavedProfile();
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    FocusScope.of(context).unfocus();
    setState(() {
      _syncFormWithSavedProfile();
      _stackController.clear();
      _isEditing = false;
    });
  }

  void _addStackItem() {
    final value = _stackController.text.trim();
    if (value.isEmpty) {
      return;
    }

    final exists = _techStack.any(
      (item) => item.toLowerCase() == value.toLowerCase(),
    );
    if (exists) {
      _showSnackBar('This stack item is already added.');
      return;
    }

    setState(() {
      _techStack = <String>[..._techStack, value];
      _stackController.clear();
    });
  }

  void _removeStackItem(String value) {
    setState(() {
      _techStack = _techStack.where((item) => item != value).toList();
    });
  }

  void _onBottomNavTapped(int index) {
    if (index == 0) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
      return;
    }

    if (index == 1) {
      Navigator.pushNamed(context, '/practice');
      return;
    }

    if (index == 2) {
      Navigator.pushNamed(context, '/reports');
      return;
    }
  }

  String _normalizeLevel(String raw) {
    final normalized = raw.trim().toLowerCase();
    return _levelOptions.contains(normalized) ? normalized : '';
  }

  String _displayLevel(String level) {
    if (level.isEmpty) {
      return 'Not set';
    }

    return '${level[0].toUpperCase()}${level.substring(1)}';
  }

  String _profileInitial() {
    if (_name.trim().isNotEmpty) {
      return _name.trim()[0].toUpperCase();
    }

    if (_email.trim().isNotEmpty) {
      return _email.trim()[0].toUpperCase();
    }

    return 'U';
  }

  DateTime _toDateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  Map<DateTime, int> _buildActivityMap({
    required List<DateTime> interviewDates,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final map = <DateTime, int>{};

    for (final raw in interviewDates) {
      final date = _toDateOnly(raw);
      if (date.isBefore(startDate) || date.isAfter(endDate)) {
        continue;
      }
      map[date] = (map[date] ?? 0) + 1;
    }

    return map;
  }

  int _calculateCurrentStreak(Map<DateTime, int> map, DateTime endDate) {
    var streak = 0;
    var cursor = endDate;

    while (true) {
      if ((map[cursor] ?? 0) > 0) {
        streak += 1;
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      break;
    }

    return streak;
  }

  Color _activityColor(int count) {
    if (count <= 0) {
      return const Color(0xFFE9ECF9);
    }
    if (count == 1) {
      return const Color(0xFFC8CEFF);
    }
    if (count == 2) {
      return const Color(0xFFA5B0FF);
    }
    if (count == 3) {
      return const Color(0xFF838FFF);
    }
    return const Color(0xFF6C63FF);
  }

  String _formatAverageScore() {
    final score = _averageScorePercent;
    if (score == null) {
      return 'N/A';
    }

    return '${score.round()}%';
  }

  void _openSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildThemeToggleTile(compact: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeToggleTile({bool compact = false}) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeController.themeMode,
      builder: (context, mode, _) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        );

        return SwitchListTile.adaptive(
          value: isDark,
          onChanged: (value) {
            _themeController.setThemeMode(
              value ? ThemeMode.dark : ThemeMode.light,
            );
          },
          dense: compact,
          contentPadding: compact
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 4),
          secondary: Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          ),
          title: Text(
            'Dark mode',
            style: compact
                ? theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  )
                : theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
          ),
          subtitle: compact
              ? null
              : Text('Use darker colors across the app.', style: subtitleStyle),
        );
      },
    );
  }

  Widget _buildAppearanceSection() {
    return _buildSoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: _buildThemeToggleTile(),
    );
  }

  Widget _buildSoftCard({required Widget child, EdgeInsets? padding}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.6 : 0.3,
          ),
        ),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: child,
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildCircleIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context, true),
        ),
        const Expanded(
          child: Text(
            'Profile',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        _buildCircleIconButton(
          icon: Icons.settings_outlined,
          onTap: _openSettingsSheet,
        ),
      ],
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: isDark
              ? const []
              : [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
      ),
    );
  }

  Widget _buildProfileSection() {
    final theme = Theme.of(context);
    final premiumBadgeLabel = _resolvePremiumBadgeLabel();
    final premiumBadgeStyle = _resolvePremiumBadgeStyle(
      brightness: theme.brightness,
      surfaceColor: theme.colorScheme.surface,
    );

    return SizedBox(
      width: double.infinity,
      child: _buildSoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF6C63FF), Color(0xFF6A8BFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x336C63FF),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _profileInitial(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_isPremium)
                  Positioned(
                    bottom: -8,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: premiumBadgeStyle.backgroundColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        premiumBadgeLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: premiumBadgeStyle.textColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              '${_name.trim().isEmpty ? 'User' : _name.trim()} 👋',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              _email.isEmpty ? 'No email available' : _email,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _resolvePremiumBadgeLabel() {
    if (!_isPremium) {
      return '';
    }

    final planId = _premiumPlanId?.trim();
    if (planId == null || planId.isEmpty) {
      return 'Premium';
    }

    final normalized = planId.toLowerCase();
    for (final plan in kPremiumPlans) {
      if (plan.id.toLowerCase() == normalized) {
        return plan.name;
      }
    }

    return 'Premium';
  }

  _PremiumBadgeStyle _resolvePremiumBadgeStyle({
    required Brightness brightness,
    required Color surfaceColor,
  }) {
    final baseColor = _resolvePremiumBadgeBaseColor();

    return _buildPremiumBadgeStyle(
      baseColor: baseColor,
      brightness: brightness,
      surfaceColor: surfaceColor,
    );
  }

  Color _resolvePremiumBadgeBaseColor() {
    if (!_isPremium) {
      return AppColors.primaryLight;
    }

    final planId = _premiumPlanId?.trim().toLowerCase();
    switch (planId) {
      case 'starter':
        return AppColors.onboarding3;
      case 'pro':
        return AppColors.onboarding1;
      case 'elite':
        return AppColors.onboarding4;
      default:
        return AppColors.primaryLight;
    }
  }

  _PremiumBadgeStyle _buildPremiumBadgeStyle({
    required Color baseColor,
    required Brightness brightness,
    required Color surfaceColor,
  }) {
    final backgroundOpacity = brightness == Brightness.dark ? 0.32 : 0.16;
    final backgroundColor = Color.alphaBlend(
      baseColor.withValues(alpha: backgroundOpacity),
      surfaceColor,
    );
    final textColor = brightness == Brightness.dark
        ? (Color.lerp(baseColor, Colors.white, 0.35) ?? baseColor)
        : baseColor;

    return _PremiumBadgeStyle(
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }

  Widget _buildPrimaryActions() {
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isEditing ? _cancelEditing : _startEditing,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              elevation: 6,
              shadowColor: const Color(0x446C63FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(_isEditing ? 'Close Edit Mode' : 'Edit Profile'),
          ),
        ),
        if (!_isEditing) ...[
          const SizedBox(height: 10),
          _buildSoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE9FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.work_outline_rounded,
                    color: Color(0xFF2A5FD9),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target Job Role',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _savedRole.isEmpty ? 'Not set yet' : _savedRole,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubscriptionSection() {
    final theme = Theme.of(context);
    final currentPlan = _resolveCurrentPlan();
    final nextPlan = _resolveUpgradePlan(currentPlan);
    final currentPlanLabel = currentPlan == null
        ? 'Premium'
        : '${currentPlan.name} • \$${currentPlan.priceUsd}/mo';
    final currentPlanDescription = currentPlan == null
        ? 'Premium plan active'
        : currentPlan.description;

    return _buildSoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFD14343),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Premium subscription',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Status: Active',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Current plan: $currentPlanLabel',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currentPlanDescription,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Canceling ends Premium immediately and locks premium-only '
            'features. You can upgrade again anytime.',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          if (nextPlan != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  final limitLabel = nextPlan.hasUnlimitedPractice
                      ? 'unlimited practice sessions'
                      : 'up to ${nextPlan.dailyPracticeLimit} sessions per day';

                  Navigator.pushNamed(
                    context,
                    PaywallScreen.routeName,
                    arguments: PaywallRouteArguments(
                      title: 'Upgrade Plan',
                      featureName: '${nextPlan.name} plan',
                      message:
                          'Upgrade to ${nextPlan.name} for ${nextPlan.questionsPerSession} questions per session and $limitLabel.',
                      featureHighlights: nextPlan.features,
                      initialPlanId: nextPlan.id,
                    ),
                  );
                },
                icon: const Icon(Icons.trending_up_rounded),
                label: Text('Upgrade to ${nextPlan.name}'),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'You are already on the highest plan.',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isCancellingPremium ? null : _handleCancelPremium,
              icon: _isCancellingPremium
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel_rounded),
              label: Text(
                _isCancellingPremium ? 'Cancelling...' : 'Cancel subscription',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD14343),
                side: const BorderSide(color: Color(0xFFF0C3C3)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PremiumPlan? _resolveCurrentPlan() {
    if (!_isPremium) {
      return null;
    }

    return premiumPlanById(_premiumPlanId);
  }

  PremiumPlan? _resolveUpgradePlan(PremiumPlan? currentPlan) {
    if (currentPlan == null) {
      return null;
    }

    final index = kPremiumPlans.indexWhere((plan) => plan.id == currentPlan.id);
    if (index == -1 || index >= kPremiumPlans.length - 1) {
      return null;
    }

    return kPremiumPlans[index + 1];
  }

  Widget _buildSubscriptionUpsellSection() {
    final theme = Theme.of(context);

    const perks = <String>[
      'Unlimited practice sessions',
      'Detailed AI feedback and model answers',
      'Advanced reports with weak areas',
    ];

    return _buildSoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFF2D4FD7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Premium subscription',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Status: Inactive',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Unlock Premium to practice without limits and see deeper insights.',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          ...perks.map(
            (perk) => Padding(
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
                      perk,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  PaywallScreen.routeName,
                  arguments: const PaywallRouteArguments(
                    title: 'Upgrade to Premium',
                    featureName: 'Premium features',
                    message:
                        'Upgrade to unlock unlimited practice sessions, AI feedback, and advanced reports.',
                  ),
                );
              },
              icon: const Icon(Icons.rocket_launch_rounded),
              label: const Text('Upgrade to Premium'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.mic_none_rounded,
            value: _completedInterviews.toString(),
            label: 'Interviews\nCompleted',
            iconBackground: const Color(0xFFEDEBFF),
            iconColor: const Color(0xFF6C63FF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.show_chart_rounded,
            value: _formatAverageScore(),
            label: 'Average\nScore',
            iconBackground: const Color(0xFFE6F7F5),
            iconColor: const Color(0xFF1A9D8B),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.access_time_rounded,
            value: '${_currentStreak}d',
            label: 'Current\nStreak',
            iconBackground: const Color(0xFFFFF0E0),
            iconColor: const Color(0xFFE8812E),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color iconBackground,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);

    return _buildSoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.2,
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    final theme = Theme.of(context);

    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day);
    final startDate = endDate.subtract(
      const Duration(days: _activityWeeks * 7 - 1),
    );
    final activityMap = _buildActivityMap(
      interviewDates: _interviewDates,
      startDate: startDate,
      endDate: endDate,
    );

    final totalInterviews = activityMap.values.fold<int>(
      0,
      (total, value) => total + value,
    );

    return _buildSoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Interview Activity',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '$totalInterviews interviews in the last $_activityWeeks weeks',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List<Widget>.generate(_activityWeeks, (weekIndex) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: weekIndex == _activityWeeks - 1 ? 0 : 4,
                    ),
                    child: Column(
                      children: List<Widget>.generate(7, (dayIndex) {
                        final index = (weekIndex * 7) + dayIndex;
                        final date = startDate.add(Duration(days: index));
                        final dateOnly = DateTime(
                          date.year,
                          date.month,
                          date.day,
                        );
                        final count = activityMap[dateOnly] ?? 0;

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: dayIndex == 6 ? 0 : 4,
                          ),
                          child: Tooltip(
                            message:
                                '${date.day}/${date.month}: $count interviews',
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _activityColor(count),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Less',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              ...List<Widget>.generate(5, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: index == 4 ? 0 : 4),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _activityColor(index),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 6),
              Text(
                'More',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTinyMetricChip(
                label: 'Active Days',
                value: _activeDays.toString(),
              ),
              const SizedBox(width: 8),
              _buildTinyMetricChip(
                label: 'Best Day',
                value: '$_bestDayCount interviews',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTinyMetricChip({required String label, required String value}) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final trackedDays = _activityWeeks * 7;
    final consistencyProgress = trackedDays == 0
        ? 0.0
        : (_activeDays / trackedDays).clamp(0, 1);
    final consistencyProgressDouble = consistencyProgress.toDouble();
    final premiumAchievementUnlocked = _isPremium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Achievements',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () => _showSnackBar('More achievements coming soon.'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildAchievementActiveCard(),
              const SizedBox(width: 12),
              _buildAchievementProgressCard(consistencyProgressDouble),
              const SizedBox(width: 12),
              _buildAchievementLockedCard(
                isUnlocked: premiumAchievementUnlocked,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCardShell({required Widget child}) {
    return SizedBox(
      width: 152,
      height: 176,
      child: _buildSoftCard(padding: const EdgeInsets.all(14), child: child),
    );
  }

  Widget _buildAchievementActiveCard() {
    final theme = Theme.of(context);

    return _buildAchievementCardShell(
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEDEBFF),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Interview Starter',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            _completedInterviews > 0
                ? '$_completedInterviews completed'
                : 'No interviews yet',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementProgressCard(double progress) {
    final theme = Theme.of(context);

    return _buildAchievementCardShell(
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  color: const Color(0xFFE88934),
                  backgroundColor: const Color(0xFFFFE8D3),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Consistency',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '$_activeDays active days',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementLockedCard({required bool isUnlocked}) {
    final theme = Theme.of(context);

    final title = isUnlocked ? 'Premium Profile' : 'Premium Profile';
    final subtitle = isUnlocked ? 'Unlocked' : 'Upgrade to unlock';

    return _buildAchievementCardShell(
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? const Color(0xFFE8F6EE)
                  : const Color(0xFFF1F3F7),
            ),
            child: Icon(
              isUnlocked ? Icons.verified_rounded : Icons.lock_outline_rounded,
              color: isUnlocked
                  ? const Color(0xFF1D6B44)
                  : const Color(0xFF8A93A6),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditFormCard() {
    return _buildSoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Profile',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _email.isEmpty ? 'No email available' : _email,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _roleController,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Role',
              hintText: 'e.g., Flutter Developer',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedLevel,
            decoration: const InputDecoration(labelText: 'Experience Level'),
            items: _levelOptions
                .map(
                  (level) => DropdownMenuItem<String>(
                    value: level,
                    child: Text(_displayLevel(level)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() => _selectedLevel = value);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _stackController,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _addStackItem(),
                  decoration: const InputDecoration(
                    labelText: 'Tech Stack',
                    hintText: 'Add one item',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addStackItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_techStack.isEmpty)
            const Text(
              'Add at least one stack item.',
              style: TextStyle(color: Colors.red),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _techStack
                  .map(
                    (item) => Chip(
                      label: Text(item),
                      onDeleted: () => _removeStackItem(item),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _cancelEditing,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving || !_isFormValid ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    if (_isEditing) ...[
                      _buildPrimaryActions(),
                      const SizedBox(height: 16),
                      _buildEditFormCard(),
                      const SizedBox(height: 14),
                    ] else ...[
                      _buildProfileSection(),
                      const SizedBox(height: 16),
                      _buildPrimaryActions(),
                      const SizedBox(height: 16),
                      _buildAppearanceSection(),
                      if (_isPremium) ...[
                        const SizedBox(height: 16),
                        _buildSubscriptionSection(),
                      ] else ...[
                        const SizedBox(height: 16),
                        _buildSubscriptionUpsellSection(),
                      ],
                      const SizedBox(height: 16),
                      _buildStatsGrid(),
                      const SizedBox(height: 16),
                      _buildActivityCard(),
                      const SizedBox(height: 16),
                      _buildAchievementsSection(),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: _onBottomNavTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.record_voice_over_outlined),
            activeIcon: Icon(Icons.record_voice_over_rounded),
            label: 'Practice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_outlined),
            activeIcon: Icon(Icons.show_chart_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
