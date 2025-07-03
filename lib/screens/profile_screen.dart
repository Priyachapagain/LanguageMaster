import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color greenPrimary = Color(0xFF4CAF50);
  static const Color greenAccent = Color(0xFF81C784);
  static const backgroundGradient = LinearGradient(
    colors: [Color(0xFFE8F5E9), Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  final List<String> avatars = const [
    'assets/avatars/avatar1.png',
    'assets/avatars/avatar2.png',
    'assets/avatars/avatar3.png',
    'assets/avatars/avatar4.png',
    'assets/avatars/avatar5.png',
  ];

  String getAvatarForUser(String uid) {
    final index = uid.hashCode % avatars.length;
    return avatars[index];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user!.uid;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: userDoc.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final userData = snapshot.data!;
              final email = userData['email'] ?? 'Unknown';
              final name = email.split('@')[0];
              final xp = userData['xp'] ?? 0;
              final streak = userData['streak'] ?? 0;
              final avatar = getAvatarForUser(userId);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ✅ Back Button & Title
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: greenPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Text(
                        "Your Profile",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: greenPrimary,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // to balance the back button
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ✅ Avatar
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: AssetImage(avatar),
                  ),
                  const SizedBox(height: 20),

                  // ✅ Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                      color: greenPrimary,
                    ),
                  ),

                  // ✅ Email
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade800,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ✅ "Your Stats" Title
                  const Text(
                    "Your Stats",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: greenPrimary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ✅ Stats Card (Now Green!)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [greenPrimary, greenAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 32),
                            const SizedBox(height: 4),
                            Text(
                              "$xp XP",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(Icons.local_fire_department,
                                color: Colors.orange, size: 32),
                            const SizedBox(height: 4),
                            Text(
                              "$streak",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
