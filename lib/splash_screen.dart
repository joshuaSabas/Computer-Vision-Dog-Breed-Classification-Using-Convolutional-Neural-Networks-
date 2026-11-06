import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Maghihintay ng 3 segundo bago pumunta sa Home
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/splash_logo.png', // Pangalan ng picture mo
          width: MediaQuery.of(context).size.width * 0.85,
          fit: BoxFit.contain,
          // Fallback kung sakaling mawala ang image
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.pets, size: 100, color: Color(0xFF0056D2));
          },
        ),
      ),
    );
  }
}
