import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/new_notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/utils.dart';

class WelcomeWidget extends StatefulWidget {
  final VoidCallback onHeartTap;
  final VoidCallback onNotificationTap;

  const WelcomeWidget({
    Key? key,
    required this.onHeartTap,
    required this.onNotificationTap,
  }) : super(key: key);

  @override
  State<WelcomeWidget> createState() => _WelcomeWidgetState();
}

class _WelcomeWidgetState extends State<WelcomeWidget> {
  Stream<int> unseenNotificationsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('bangerOwnerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.where((doc) {
            final seenBy = List<String>.from(doc['seenBy'] ?? []);
            return !seenBy.contains(userId);
          }).length;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/images/Group (1).png', width: 30, height: 30),
          Row(
            children: [
              Text(
                'Welcome back!',
                style: appThemes.Large.copyWith(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              // Right Section: Icons
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onHeartTap,
                    child: const Icon(
                      Icons.star_border,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  GestureDetector(
                    onTap: widget.onNotificationTap,
                    child: StreamBuilder<int>(
                      stream: unseenNotificationsStream(
                        FirebaseAuth.instance.currentUser!.uid,
                      ),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Main Notification Icon
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Icon(
                                Icons.notifications,
                                color: Colors.white,
                                size: 24.w,
                              ),
                            ),

                            // Badge
                            if (count > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: count > 99 ? 4.w : 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 18.w,
                                    minHeight: 18.h,
                                  ),
                                  child: Text(
                                    count > 99 ? '99+' : count.toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  FollowRequestIconButton(),
                  // IconButton(
                  //   onPressed: () {
                  //     Get.to(() => NewNotificationScreen());
                  //   },
                  //   icon: Image.asset(
                  //     'assets/images/social.png',
                  //     width: 30,
                  //     height: 30,
                  //     color: appColors.white,
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'What do you feel like discovering today?',
            style: appThemes.small.copyWith(
              color: appColors.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';

class FollowRequestIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color iconColor;
  final Color badgeColor;
  final Color badgeTextColor;
  final double iconSize;

  const FollowRequestIconButton({
    super.key,
    this.onTap,
    this.iconColor = Colors.white,
    this.badgeColor = Colors.red,
    this.badgeTextColor = Colors.white,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .collection('followRequests')
              .where('status', isEqualTo: 'pending') // ✅ only filter by status
              .snapshots(),
      builder: (context, snapshot) {
        int unreadCount = 0;

        if (snapshot.hasData) {
          unreadCount =
              snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['seen'] == false || !data.containsKey('seen');
              }).length;
        }

        return GestureDetector(
          onTap: onTap ?? () => Get.to(() => const NewNotificationScreen()),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Icon
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.person_add_alt_1,
                  color: iconColor,
                  size: iconSize.w,
                ),
              ),

              // Badge
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: unreadCount > 99 ? 4.w : 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 18.w,
                      minHeight: 18.h,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: TextStyle(
                        color: badgeTextColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
