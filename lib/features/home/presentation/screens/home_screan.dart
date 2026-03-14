import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jahiz/core/services/auth_service.dart';
import 'package:jahiz/features/auth/presentation/screens/auth_screen.dart';

class HomeScrean extends StatefulWidget {
  const HomeScrean({super.key});

  @override
  State<HomeScrean> createState() => _HomeScreanState();
}

class _HomeScreanState extends State<HomeScrean> {
  final AuthService _authService = AuthService();

  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      CupertinoPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 93, 57, 237),
      appBar: AppBar(
        title: const Text('Jahiz'),
        backgroundColor: const Color.fromARGB(255, 93, 57, 237),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome to Jahiz Home Screen',
          selectionColor: CupertinoColors.link,
          style: TextStyle(fontSize: 30),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
