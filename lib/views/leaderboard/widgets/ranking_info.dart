import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/widgets/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class RankingInfoDialog extends StatelessWidget {
  const RankingInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: appColors.purple,
      // title: Text("Confirmation"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: 50, height: 50),
                Icon(
                  Icons.question_mark_rounded,
                  size: 40.sp,
                  color: appColors.white,
                ),
                IconButton(
                  onPressed: () {
                    Get.back();
                  },
                  icon: Icon(Icons.close, color: appColors.white),
                ),
              ],
            ),
            SizedBox(height: 20),

            Text(
              'How the ranking work?',
              style: appThemes.Large.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              textAlign: TextAlign.left,
              """ With Bangerdrop, collect points by executing actions on the app and place yourself on top of the leaderboard. 
      
      Droppers are ranked by their score and compete in different categories of music addicts from Novice (0 to 1000 pts) to Godlike (over 1.000.000 pts). 
      
      Show your love for music and share it with your friends or even publicly to the world and get rewards from your hard work.
      
      There are long term achievements but also monthly and weekly ones so stay alert for each week’s new goals to make sure not to miss easy ways to raise your score and become the ultimate musical influencer.
      
      RANKING
      
      1 – Novice (up to 1000pts)
      2 – Apprentice (1000 to 5000 pts)
      3 – Enthusiastic (5000 to 10 000 pts)
      4 – Advisor (10 000 to 20 000 pts)
      5 – Human orchestra (20 000 to 50 000 pts)
      6 – Passionate (50 000 to 100 000 pts)
      7 – Expert (100 000 à 250 000 pts)
      8 – Minister of sound (250 000 à 500 000 pts)
      9 – Emperor (500 000 à 1 000 000 pts)
      10 – Godlike (1 000 000 pts and over)
      
      """,
              style: appThemes.small,
            ),

            SizedBox(height: 20),
            roundButton(
              text: "Continue",
              backgroundGradient: LinearGradient(
                colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderColor: appColors.white,
              textColor: appColors.white,
              onPressed: () {
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
}
