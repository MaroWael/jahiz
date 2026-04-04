import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:jahiz/core/constants/app_colors.dart';
import 'package:jahiz/firebase_options.dart';
import 'package:jahiz/features/home/presentation/screens/reports_screen.dart';
import 'package:jahiz/features/practice/presentation/screens/practice_screen.dart';
import 'package:jahiz/features/splash/presentation/screens/splash_screen.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
      ),
      routes: {
        '/practice': (_) => const PracticeScreen(),
        '/answer': (_) => const PracticeScreen(),
        '/reports': (_) => const ReportsScreen(),
      },
      home: const SplashScreen(),
    );
  }
}
