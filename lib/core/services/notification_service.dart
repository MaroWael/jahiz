import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Reserved for handling notification taps when app is in background isolate.
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int welcomeNotificationId = 1001;
  static const int resultNotificationId = 1002;
  static const int dailyChallengeNotificationId = 2001;
  static const int followUpReminderId = 3001;
  static const int testNotificationId = 9001;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'interview_prep_channel',
        'Interview Prep Notifications',
        description:
            'Notifications for reminders, results, and daily challenges.',
        importance: Importance.high,
      );

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize({
    required void Function(String? payload) onNotificationTap,
  }) async {
    if (_isInitialized) {
      return;
    }

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onNotificationTap(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _configureLocalTimeZone();
    await _createAndroidChannel();
    await requestNotificationPermission();

    _isInitialized = true;
  }

  Future<void> requestNotificationPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidPlugin?.requestNotificationsPermission();

    final IOSFlutterLocalNotificationsPlugin? iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    final MacOSFlutterLocalNotificationsPlugin? macPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    await macPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      _notificationDetails(),
      payload: payload,
    );
  }

  Future<void> showWelcomeNotificationDelayed({
    Duration delay = const Duration(seconds: 3),
  }) async {
    await Future<void>.delayed(delay);

    await showInstantNotification(
      id: welcomeNotificationId,
      title: 'Welcome 👋',
      body: "Ready to level up your interview skills? Let's start!",
      payload: '/practice',
    );
  }

  Future<void> showResultNotification({
    required int score,
    required int total,
  }) async {
    await showInstantNotification(
      id: resultNotificationId,
      title: 'Result 🎉',
      body: 'You scored $score/$total. Keep going!',
      payload: '/reports',
    );
  }

  Future<void> scheduleDailyChallenge({
    required TimeOfDay time,
    required String question,
  }) async {
    final tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);

    await _notificationsPlugin.zonedSchedule(
      dailyChallengeNotificationId,
      'Daily Challenge 🔥',
      question,
      scheduledDate,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/practice',
    );
  }

  Future<void> scheduleFollowUpReminder({int days = 2}) async {
    final tz.TZDateTime scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(days: days));

    await _notificationsPlugin.zonedSchedule(
      followUpReminderId,
      'We miss you 👀',
      'Come back and continue your interview prep!',
      scheduledDate,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '/practice',
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  NotificationDetails _notificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> _createAndroidChannel() async {
    if (!Platform.isAndroid) {
      return;
    }

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidPlugin?.createNotificationChannel(_androidChannel);
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();

    try {
      final String localTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimeZone));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }
}
