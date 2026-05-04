import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:jahiz/core/models/notification_inbox_item.dart';

class NotificationInboxService {
  static const String _storageKey = 'notification_inbox_items';
  static const int _maxItems = 50;

  Future<List<NotificationInboxItem>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <NotificationInboxItem>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <NotificationInboxItem>[];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(NotificationInboxItem.fromJson)
          .toList();
    } catch (_) {
      return <NotificationInboxItem>[];
    }
  }

  Future<int> getUnreadCount() async {
    final items = await getNotifications();
    return items.where((item) => !item.isRead).length;
  }

  Future<void> addNotification({
    required int notificationId,
    required String title,
    required String body,
    String? payload,
  }) async {
    final items = await getNotifications();
    final entry = NotificationInboxItem(
      id: _newId(),
      notificationId: notificationId,
      title: title,
      body: body,
      payload: payload,
      createdAt: DateTime.now(),
      isRead: false,
    );

    items.insert(0, entry);
    await _save(_trim(items));
  }

  Future<void> upsertScheduledNotification({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledFor,
    String? payload,
  }) async {
    final items = await getNotifications();
    final index = items.indexWhere(
      (item) => item.notificationId == notificationId && item.isScheduled,
    );

    final entry = NotificationInboxItem(
      id: _newId(),
      notificationId: notificationId,
      title: title,
      body: body,
      payload: payload,
      createdAt: DateTime.now(),
      scheduledFor: scheduledFor,
      isRead: true,
    );

    if (index == -1) {
      items.insert(0, entry);
    } else {
      items.removeAt(index);
      items.insert(0, entry);
    }

    await _save(_trim(items));
  }

  Future<void> markAllRead() async {
    final items = await getNotifications();
    final updated = items
        .map((item) => item.isRead ? item : item.copyWith(isRead: true))
        .toList();

    await _save(updated);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _save(List<NotificationInboxItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, payload);
  }

  List<NotificationInboxItem> _trim(List<NotificationInboxItem> items) {
    if (items.length <= _maxItems) {
      return items;
    }
    return items.take(_maxItems).toList();
  }

  String _newId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
