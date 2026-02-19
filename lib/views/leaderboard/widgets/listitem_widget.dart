import 'package:banger_drop/consts/consts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_rx/src/rx_typedefs/rx_typedefs.dart';

class LeaderboardListItem extends StatelessWidget {
  final int rank;
  final String name;
  final int points;
  final String imageUrl;
  final Callback onTap;

  const LeaderboardListItem({
    super.key,
    required this.rank,
    required this.name,
    required this.points,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF5A1E8E), // purple background
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            // Rank
            Text('$rank', style: appThemes.Large),
            const SizedBox(width: 16),
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.pinkAccent, width: 3),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 56, // radius * 2 (28 * 2)
                  height: 56,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey[300],
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey[300],
                        child: const Icon(Icons.person),
                      ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Name and Points
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 160.w,
                  child: Text(name, style: appThemes.Medium),
                ),
                Text(
                  '$points Points',
                  style: appThemes.small.copyWith(fontFamily: 'Sans'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
