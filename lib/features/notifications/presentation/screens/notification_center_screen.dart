import 'package:flutter/material.dart';
import 'package:jahiz/core/constants/app_colors.dart';
import 'package:jahiz/core/models/notification_inbox_item.dart';
import 'package:jahiz/core/services/app_preferences_service.dart';
import 'package:jahiz/core/services/notification_inbox_service.dart';
import 'package:jahiz/core/services/notification_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  static const String routeName = '/notifications';

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationInboxService _inboxService = NotificationInboxService();
  final AppPreferencesService _preferencesService = AppPreferencesService();

  List<NotificationInboxItem> _items = <NotificationInboxItem>[];
  NotificationPermissionState _permissionState =
      NotificationPermissionState.unknown;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load(markRead: true);
  }

  Future<void> _load({bool markRead = false}) async {
    if (markRead) {
      await _inboxService.markAllRead();
    }

    final items = await _inboxService.getNotifications();
    final permissionState = await _preferencesService
        .getNotificationPermissionState();

    if (!mounted) {
      return;
    }

    setState(() {
      _items = items;
      _permissionState = permissionState;
      _isLoading = false;
    });
  }

  Future<void> _refresh() async {
    await _load();
  }

  Future<void> _requestPermission() async {
    final granted = await NotificationService.instance
        .requestNotificationPermission();
    await _preferencesService.setNotificationPermissionState(
      granted
          ? NotificationPermissionState.granted
          : NotificationPermissionState.denied,
    );

    if (granted) {
      await NotificationService.instance.ensureDailyPracticeReminder();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enable notifications from system settings to receive reminders.',
          ),
        ),
      );
    }

    await _load();
  }

  Future<void> _clearAll() async {
    await _inboxService.clearAll();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FB),
        elevation: 0,
        title: const Text('Notifications'),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              tooltip: 'Clear all',
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildPermissionBanner(),
                    if (_items.isEmpty)
                      _buildEmptyState()
                    else
                      ..._items.map(_buildNotificationCard),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPermissionBanner() {
    if (_permissionState == NotificationPermissionState.granted) {
      return const SizedBox.shrink();
    }

    final message = _permissionState == NotificationPermissionState.denied
        ? 'Notifications are disabled. Enable them in system settings.'
        : 'Enable notifications to receive practice reminders.';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _requestPermission,
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.notifications_none_rounded, size: 40),
          SizedBox(height: 10),
          Text(
            'No notifications yet',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'We will save your reminders and updates here.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationInboxItem item) {
    final timestamp = item.scheduledFor != null
        ? 'Scheduled for ${_formatDateTime(item.scheduledFor!)}'
        : _formatDateTime(item.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110E1644),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.scheduledFor == null
                  ? Icons.notifications_active_outlined
                  : Icons.schedule_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(item.body, style: const TextStyle(height: 1.3)),
                const SizedBox(height: 8),
                Text(
                  timestamp,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}
