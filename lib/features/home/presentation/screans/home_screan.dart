import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeScrean extends StatefulWidget {
  const HomeScrean({super.key});

  @override
  State<HomeScrean> createState() => _HomeScreanState();
}

class _HomeScreanState extends State<HomeScrean> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 93, 57, 237),
      appBar: AppBar(title: const Text("Jahiz") , backgroundColor: const Color.fromARGB(255, 93, 57, 237),),
      body: const Center(child: Text("Welcome to Jahiz Home Screen" , selectionColor: CupertinoColors.link, style: TextStyle(fontSize: 30),)),
    );
  }
}
