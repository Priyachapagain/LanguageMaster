import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'level_screen.dart';

class CongratulationsScreen extends StatefulWidget {
  final int levelNumber;

  const CongratulationsScreen({super.key, required this.levelNumber});

  @override
  State<CongratulationsScreen> createState() => _CongratulationsScreenState();
}

class _CongratulationsScreenState extends State<CongratulationsScreen> {
  static const Color greenPrimary = Color(0xFF4CAF50);

  bool _isLoading = true;
  int _streak = 1;

  @override
  void initState() {
    super.initState();
    _completeLevel();
  }

  Future<void> _completeLevel() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    final nextLevel = widget.levelNumber + 1;

    await userDoc
        .collection('levels')
        .doc('level_$nextLevel')
        .set({'isUnlocked': true}, SetOptions(merge: true));

    final userSnapshot = await userDoc.get();
    final lastActive = userSnapshot.data()?['lastActive'] as Timestamp?;
    int streak = userSnapshot.data()?['streak'] ?? 0;

    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);

    if (widget.levelNumber == 1) {
      streak = 1;
    } else {
      if (lastActive != null) {
        final lastDate = lastActive.toDate().toUtc();
        final lastDay = DateTime.utc(lastDate.year, lastDate.month, lastDate.day);
        final difference = today.difference(lastDay).inDays;

        if (difference == 1) {
          streak++;
        } else if (difference > 1) {
          streak = 1;
        }
      } else {
        // First activity ever
        streak = 1;
      }
    }

    await userDoc.set({
      'xp': FieldValue.increment(20),
      'streak': streak,
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      _isLoading = false;
      _streak = streak;
    });
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
        decoration: const BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator()
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/animation/congratulation1.json',
                  width: 250,
                  height: 250,
                ),
                const SizedBox(height: 20),
                const Text(
                  "🎉 Hurray!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: greenPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "You’ve completed this level!",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.orangeAccent,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Streak: $_streak days",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LevelScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenPrimary,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Back to Levels",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
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
