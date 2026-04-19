import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:jahiz/core/constants/app_colors.dart';
import 'package:jahiz/core/services/notification_service.dart';
import 'package:jahiz/firebase_options.dart';
import 'package:jahiz/features/home/presentation/screens/reports_screen.dart';
import 'package:jahiz/features/paywall/presentation/screens/payment_screen.dart';
import 'package:jahiz/features/paywall/presentation/screens/paywall_screen.dart';
import 'package:jahiz/features/paywall/presentation/screens/success_screen.dart';
import 'package:jahiz/features/practice/presentation/screens/practice_screen.dart';
import 'package:jahiz/features/splash/presentation/screens/splash_screen.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService.instance.initialize(
    onNotificationTap: (payload) {
      if (payload == null || payload.isEmpty) {
        return;
      }
      _navigatorKey.currentState?.pushNamed(payload);
    },
  );

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    unawaited(NotificationService.instance.showWelcomeNotificationDelayed());
    unawaited(_resetFollowUpReminder());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_resetFollowUpReminder());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _resetFollowUpReminder() async {
    await NotificationService.instance.cancelNotification(
      NotificationService.followUpReminderId,
    );
    await NotificationService.instance.scheduleFollowUpReminder(days: 2);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
      ),
      routes: {
        '/practice': (_) => const PracticeScreen(),
        '/answer': (_) => const PracticeScreen(isDailyQuestionMode: true),
        '/reports': (_) => const ReportsScreen(),
        PaywallScreen.routeName: (_) => const PaywallScreen(),
        PaymentScreen.routeName: (_) => const PaymentScreen(),
        SuccessScreen.routeName: (_) => const SuccessScreen(),
      },
      home: const SplashScreen(),
    );
  }
}
