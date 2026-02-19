import 'package:banger_drop/consts/consts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/get_core.dart';
import 'package:get/get_rx/src/rx_typedefs/rx_typedefs.dart';

class PersonInfo extends StatelessWidget {
  final String imgUrl;
  final String name;
  final int points;
  final int followers;
  final int following;
  final Callback settingsTap;

  const PersonInfo({
    super.key,
    required this.imgUrl,
    required this.name,
    required this.points,
    required this.followers,
    required this.following,
    required this.settingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 25.sp,
                        fontWeight: FontWeight.bold,
                        foreground:
                            Paint()
                              ..shader = const LinearGradient(
                                colors: [
                                  Colors.deepPurple,
                                  Colors.pink,

                                  Colors.purple,
                                ],
                              ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Novice - $points Points',
                      style: appThemes.Medium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$followers Followers - $following Followed',
                      style: appThemes.small,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.purple, Colors.pinkAccent],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 35.r,
                      backgroundColor:
                          Colors.grey.shade800, // fallback background
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: imgUrl,
                          fit: BoxFit.cover,
                          width: 70.r,
                          height: 70.r,
                          placeholder:
                              (context, url) => const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) =>
                                  Icon(Icons.person, color: appColors.white),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      settingsTap();
                    },
                    icon: Icon(Icons.settings, color: appColors.white),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
