import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

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

  String getRandomAvatar(int index) {
    return avatars[index % avatars.length];
  }

  Color getBorderColor(int index) {
    if (index == 0) return Colors.amber;
    if (index == 1) return Colors.grey;
    if (index == 2) return Colors.white;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final leaderboardQuery = FirebaseFirestore.instance
        .collection('users'); // Do NOT order here. We sort manually.

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Text(
                  "🏆 Leaderboard",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: greenPrimary,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: leaderboardQuery.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final players = snapshot.data!.docs;

                    // Sort manually by (xp + streak * 10)
                    players.sort((a, b) {
                      final aXp = a['xp'] ?? 0;
                      final aStreak = a['streak'] ?? 0;
                      final bXp = b['xp'] ?? 0;
                      final bStreak = b['streak'] ?? 0;

                      final aScore = aXp + (aStreak * 10);
                      final bScore = bXp + (bStreak * 10);

                      return bScore.compareTo(aScore);
                    });

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final player = players[index];
                        final email = player['email'] ?? 'Unknown';
                        final name = email.split('@')[0];
                        final xp = player['xp'] ?? 0;
                        final streak = player['streak'] ?? 0;
                        final score = xp + (streak * 10);
                        final isCurrentUser = player.id == userId;

                        final avatar = getRandomAvatar(index);
                        final borderColor = getBorderColor(index);
                        final isTop3 = index < 3;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            gradient: isCurrentUser
                                ? const LinearGradient(
                              colors: [greenAccent, greenPrimary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                                : null,
                            color: isCurrentUser ? null : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: borderColor,
                                    child: CircleAvatar(
                                      radius: 28,
                                      backgroundImage: AssetImage(avatar),
                                    ),
                                  ),
                                  if (isTop3)
                                    Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: Icon(
                                        Icons.emoji_events,
                                        color: borderColor,
                                        size: 24,
                                      ),
                                    ),
                                  if (isCurrentUser)
                                    Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isCurrentUser ? "$name (You)" : name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: isCurrentUser
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Rank #${index + 1}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isCurrentUser
                                            ? Colors.white70
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "$xp XP",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isCurrentUser
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.local_fire_department,
                                    color: Colors.orange,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "$streak🔥",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isCurrentUser
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              FutureBuilder<QuerySnapshot>(
                future: leaderboardQuery.get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();

                  final allPlayers = snapshot.data!.docs;

                  // Sort the same way!
                  allPlayers.sort((a, b) {
                    final aXp = a['xp'] ?? 0;
                    final aStreak = a['streak'] ?? 0;
                    final bXp = b['xp'] ?? 0;
                    final bStreak = b['streak'] ?? 0;

                    final aScore = aXp + (aStreak * 10);
                    final bScore = bXp + (bStreak * 10);

                    return bScore.compareTo(aScore);
                  });

                  int userRank =
                      allPlayers.indexWhere((doc) => doc.id == userId) + 1;

                  final userData =
                  allPlayers.firstWhere((doc) => doc.id == userId);
                  final xp = userData['xp'] ?? 0;
                  final streak = userData['streak'] ?? 0;

                  return Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      "👑 Your Rank: #$userRank | ⭐ $xp XP | 🔥 $streak day streak",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: greenPrimary,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
