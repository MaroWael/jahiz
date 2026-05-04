import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:jahiz/core/services/app_preferences_service.dart';
import 'package:jahiz/core/services/notification_inbox_service.dart';
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
  static const int dailyPracticeReminderId = 2002;
  static const int followUpReminderId = 3001;
  static const int testNotificationId = 9001;

  static const TimeOfDay defaultDailyPracticeReminderTime = TimeOfDay(
    hour: 10,
    minute: 0,
  );

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
  final AppPreferencesService _appPreferencesService = AppPreferencesService();
  final NotificationInboxService _notificationInboxService =
      NotificationInboxService();

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

    _isInitialized = true;
  }

  Future<bool> requestNotificationPermission() async {
    bool? granted;

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      granted = await androidPlugin?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isMacOS) {
      final MacOSFlutterLocalNotificationsPlugin? macPlugin =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin
              >();
      granted = await macPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return granted ?? true;
  }

  Future<void> ensureDailyPracticeReminder({
    TimeOfDay time = defaultDailyPracticeReminderTime,
  }) async {
    final permissionState = await _appPreferencesService
        .getNotificationPermissionState();

    if (permissionState == NotificationPermissionState.denied) {
      return;
    }

    if (permissionState == NotificationPermissionState.unknown) {
      final granted = await requestNotificationPermission();
      await _appPreferencesService.setNotificationPermissionState(
        granted
            ? NotificationPermissionState.granted
            : NotificationPermissionState.denied,
      );

      if (!granted) {
        return;
      }
    }

    await _scheduleDailyPracticeReminderIfNeeded(time: time);
  }

  Future<void> refreshDailyPracticeReminderIfAllowed({
    TimeOfDay time = defaultDailyPracticeReminderTime,
  }) async {
    final permissionState = await _appPreferencesService
        .getNotificationPermissionState();

    if (permissionState != NotificationPermissionState.granted) {
      return;
    }

    await _scheduleDailyPracticeReminderIfNeeded(time: time);
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notificationInboxService.addNotification(
      notificationId: id,
      title: title,
      body: body,
      payload: payload,
    );

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

    await _notificationInboxService.upsertScheduledNotification(
      notificationId: dailyChallengeNotificationId,
      title: 'Daily Challenge',
      body: question,
      payload: '/practice',
      scheduledFor: scheduledDate.toLocal(),
    );

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

  Future<void> scheduleDailyPracticeReminder({
    TimeOfDay time = defaultDailyPracticeReminderTime,
  }) async {
    await _scheduleDailyPracticeReminderIfNeeded(time: time, force: true);
  }

  Future<void> scheduleFollowUpReminder({int days = 2}) async {
    final tz.TZDateTime scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(days: days));

    await _notificationInboxService.upsertScheduledNotification(
      notificationId: followUpReminderId,
      title: 'Follow-up reminder',
      body: 'Come back and continue your interview prep!',
      payload: '/practice',
      scheduledFor: scheduledDate.toLocal(),
    );

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

  Future<String?> _configureLocalTimeZone() async {
    tz.initializeTimeZones();

    try {
      final String localTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimeZone));
      return localTimeZone;
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
      return null;
    }
  }

  Future<void> _scheduleDailyPracticeReminderIfNeeded({
    required TimeOfDay time,
    bool force = false,
  }) async {
    final localTimeZone = await _configureLocalTimeZone();
    final wasScheduled = await _appPreferencesService
        .isDailyPracticeReminderScheduled();
    final lastTimeZone = await _appPreferencesService.getLastKnownTimeZone();
    final timeZoneChanged =
        localTimeZone != null && localTimeZone != lastTimeZone;

    if (!force && wasScheduled && !timeZoneChanged) {
      return;
    }

    await _notificationsPlugin.cancel(dailyPracticeReminderId);

    final tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);

    await _notificationInboxService.upsertScheduledNotification(
      notificationId: dailyPracticeReminderId,
      title: 'Practice reminder',
      body: 'Spend a few minutes on your interview practice today.',
      payload: '/practice',
      scheduledFor: scheduledDate.toLocal(),
    );

    await _notificationsPlugin.zonedSchedule(
      dailyPracticeReminderId,
      'Practice time',
      'Spend a few minutes on your interview practice today.',
      scheduledDate,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/practice',
    );

    await _appPreferencesService.setDailyPracticeReminderScheduled(true);
    if (localTimeZone != null && localTimeZone.isNotEmpty) {
      await _appPreferencesService.setLastKnownTimeZone(localTimeZone);
    }
  }
}
