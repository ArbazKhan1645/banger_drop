import 'package:banger_drop/consts/consts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LeaderboardTopWidget extends StatelessWidget {
  const LeaderboardTopWidget({super.key, required this.infoTap});
  final infoTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(width: 50.w),
        // IconButton(
        //   onPressed: () {},
        //   icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        // ),
        Text(
          'Leaderboard',
          style: appThemes.Large.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 25.sp,
          ),
        ),
        IconButton(
          onPressed: () {
            infoTap();
          },
          icon: Icon(Icons.question_mark_outlined, color: Colors.white),
        ),
      ],
    );
  }
}
