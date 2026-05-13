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
    hour: 14,
    minute: 00,
  );

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'interview_prep_channel_v2',
        'Interview Prep Alerts',
        description:
            'Practice reminders, daily challenges, and result updates.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AppPreferencesService _appPreferencesService = AppPreferencesService();
  final NotificationInboxService _notificationInboxService =
      NotificationInboxService();

  bool _isInitialized = false;
  bool _welcomeNotificationInFlight = false;
  bool _welcomeNotificationShownThisSession = false;

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
    if (_welcomeNotificationShownThisSession || _welcomeNotificationInFlight) {
      return;
    }

    _welcomeNotificationInFlight = true;
    try {
      await Future<void>.delayed(delay);

      if (_welcomeNotificationShownThisSession) {
        return;
      }

      await _notificationsPlugin.cancel(welcomeNotificationId);

      await showInstantNotification(
        id: welcomeNotificationId,
        title: 'Welcome 👋',
        body: "Ready to level up your interview skills? Let's start!",
        payload: '/practice',
      );

      _welcomeNotificationShownThisSession = true;
    } finally {
      _welcomeNotificationInFlight = false;
    }
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

    await _scheduleZonedNotification(
      id: dailyChallengeNotificationId,
      title: 'Daily Challenge 🔥',
      body: question,
      scheduledDate: scheduledDate,
      payload: '/practice',
      matchDateTimeComponents: DateTimeComponents.time,
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

    await _scheduleZonedNotification(
      id: followUpReminderId,
      title: 'We miss you 👀',
      body: 'Come back and continue your interview prep!',
      scheduledDate: scheduledDate,
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
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  Future<void> _scheduleZonedNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    } catch (_) {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    }
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
    final storedTime = await _appPreferencesService
        .getDailyPracticeReminderTime();
    final currentTime = _formatReminderTime(time);
    final lastTimeZone = await _appPreferencesService.getLastKnownTimeZone();
    final timeZoneChanged =
        localTimeZone != null && localTimeZone != lastTimeZone;
    final timeChanged = storedTime != currentTime;

    if (!force && wasScheduled && !timeZoneChanged && !timeChanged) {
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

    await _scheduleZonedNotification(
      id: dailyPracticeReminderId,
      title: 'Practice time',
      body: 'Spend a few minutes on your interview practice today.',
      scheduledDate: scheduledDate,
      payload: '/practice',
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _appPreferencesService.setDailyPracticeReminderScheduled(true);
    await _appPreferencesService.setDailyPracticeReminderTime(currentTime);
    if (localTimeZone != null && localTimeZone.isNotEmpty) {
      await _appPreferencesService.setLastKnownTimeZone(localTimeZone);
    }
  }

  String _formatReminderTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
