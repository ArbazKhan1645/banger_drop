import 'package:banger_drop/views/artist_profile/artist_profile_view.dart';
import 'package:banger_drop/views/leaderboard/controller/leaderboard_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class LeaderboardWidget extends StatelessWidget {
  final TimeFilter filter;

  const LeaderboardWidget({super.key, required this.filter});
  Future<List<Map<String, dynamic>>> getTopThreeUsers(TimeFilter filter) async {
    final usersQuery = FirebaseFirestore.instance.collection('users');

    if (filter != TimeFilter.AllTime) {
      // Use pointsHistory to calculate recent points
      final now = DateTime.now();
      late DateTime start;

      if (filter == TimeFilter.Daily) {
        start = DateTime(now.year, now.month, now.day);
      } else if (filter == TimeFilter.Weekly) {
        start = now.subtract(Duration(days: now.weekday - 1));
      } else if (filter == TimeFilter.Monthly) {
        start = DateTime(now.year, now.month);
      }

      final historySnapshot = await usersQuery.get();
      final List<Map<String, dynamic>> rankedUsers = [];

      for (final doc in historySnapshot.docs) {
        final data = doc.data();
        if (data == null) continue;

        final history = List<Map<String, dynamic>>.from(
          data['pointsHistory'] ?? [],
        );

        final recentPoints = history
            .where(
              (entry) =>
                  (entry['timestamp'] as Timestamp?)?.toDate().isAfter(start) ??
                  false,
            )
            .fold<int>(
              0,
              (sum, e) => sum + ((e['points'] ?? 0) as num).toInt(),
            );

        if (recentPoints > 0) {
          rankedUsers.add({
            'name': data['name'] ?? '',
            'points': recentPoints,
            'imageUrl': data['img'] ?? '',
            'uid': data['uid'] ?? '',
          });
        }
      }

      rankedUsers.sort((a, b) => b['points'].compareTo(a['points']));
      return rankedUsers.take(3).toList();
    } else {
      // Default (all time leaderboard)
      final snapshot =
          await usersQuery.orderBy('points', descending: true).limit(3).get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            if (data == null) return null;

            return {
              'name': data['name'] ?? '',
              'points': (data['points'] ?? 0) as int,
              'imageUrl': data['img'] ?? '',
              'uid': data['uid'] ?? '',
            };
          })
          .whereType<Map<String, dynamic>>() // removes any null entries
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: getTopThreeUsers(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No leaderboard data'));
        }

        final topUsers = snapshot.data!;

        // Safely get users (handle < 3 case)
        final user1 =
            topUsers.length > 0 ? topUsers[1 % topUsers.length] : null;
        final user2 =
            topUsers.length > 0 ? topUsers[0] : null; // Top 1 (center)
        final user3 = topUsers.length > 2 ? topUsers[2] : null;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (user1 != null)
                GestureDetector(
                  onTap: () {
                    Get.to(() => ArtistProfileView(userId: user1['uid'] ?? ''));
                  },
                  child: LeaderboardItem(
                    name: user1['name'],
                    points: user1['points'],
                    imageUrl: user1['imageUrl'],
                    isTop: false,
                    borderColor: Colors.grey,
                  ),
                ),
              if (user2 != null)
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: GestureDetector(
                    onTap: () {
                      Get.to(
                        () => ArtistProfileView(userId: user2['uid'] ?? ''),
                      );
                    },
                    child: LeaderboardItem(
                      name: user2['name'],
                      points: user2['points'],
                      imageUrl: user2['imageUrl'],
                      isTop: true,
                      borderColor: Colors.yellow,
                    ),
                  ),
                ),
              if (user3 != null)
                GestureDetector(
                  onTap: () {
                    Get.to(() => ArtistProfileView(userId: user3['uid'] ?? ''));
                  },
                  child: LeaderboardItem(
                    name: user3['name'],
                    points: user3['points'],
                    imageUrl: user3['imageUrl'],
                    isTop: false,
                    borderColor: Colors.orange,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class LeaderboardItem extends StatelessWidget {
  final String name;
  final int points;
  final String imageUrl;
  final bool isTop;
  final Color borderColor;

  const LeaderboardItem({
    required this.name,
    required this.points,
    required this.imageUrl,
    required this.isTop,
    required this.borderColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final imageSize = isTop ? 100.0 : 75.0;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 4),
          ),
          child: CircleAvatar(
            radius: imageSize / 2,
            backgroundColor: Colors.transparent,
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                errorWidget:
                    (context, url, error) =>
                        Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),
        SizedBox(
          width: 100,
          child: Center(
            child: Text(
              overflow: TextOverflow.ellipsis,
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isTop ? 16 : 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Text(
          '$points Points',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
      ],
    );
  }
}
