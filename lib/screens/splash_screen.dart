import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:duolingo_clone_project/screens/level_screen.dart';
import '../auth_screen/sign_in.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color greenPrimary = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), checkAuthState);
  }

  void checkAuthState() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Already signed in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LevelScreen()),
      );
    } else {
      // Not signed in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundGradient = LinearGradient(
      colors: [Color(0xFFE8F5E9), Colors.white],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Lottie.asset(
                  'assets/animation/animation.json',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                const Text(
                  "LanguageMaster",
                  style: TextStyle(
                    color: greenPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Spacer(flex: 3),
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: CircularProgressIndicator(
                    color: greenPrimary,
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
