import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/notifications/fcm_notification_sender.dart';
import 'package:banger_drop/views/chat/chat_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:get/get.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class CommentsController extends GetxController {
  final String bangerId;
  final String currentUserId;
  final String currentUserName;
  final String ownerID;
  final String bangerImg;

  CommentsController({
    required this.bangerId,
    required this.currentUserId,
    required this.currentUserName,
    required this.ownerID,
    required this.bangerImg,
  });

  var comments = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadComments();
  }

  void loadComments() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('Bangers')
            .doc(bangerId)
            .get();

    if (doc.exists) {
      final data = doc.data()!;
      final fetched = List<Map<String, dynamic>>.from(data['Comments'] ?? []);
      comments.value = fetched;
    }
  }

  final FcmNotificationSender sender = FcmNotificationSender();
  Future<bool> fetchNotificationPreference(String fieldName, String uid) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

    try {
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          // Return the value if the field exists
          if (data.containsKey(fieldName)) {
            return data[fieldName] as bool;
          }
        }
      }
    } catch (e) {
      print('Error fetching $fieldName from Firestore: $e');
    }

    // If document or field doesn't exist, return true
    return true;
  }

  Future<void> addComment(String text) async {
    if (text.trim().isEmpty) return;

    final ref = FirebaseFirestore.instance.collection('Bangers').doc(bangerId);

    final newComment = {
      'id': currentUserId,
      'name': currentUserName,
      'text': text.trim(),
      'img': AppConstants.userImg, // User's profile image
      'time': DateTime.now().toIso8601String(),
    };

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final commentsList = List<Map<String, dynamic>>.from(
        data['Comments'] ?? [],
      );
      int total = data['TotalComments'] ?? 0;

      commentsList.add(newComment);
      total += 1;

      transaction.update(ref, {
        'Comments': commentsList,
        'TotalComments': total,
      });

      comments.add(newComment); // Update UI instantly
    });

    if (await fetchNotificationPreference('social', ownerID)) {
      final targetToken = await sender.fetchFcmTokensForUser(ownerID);

      if (currentUserId != ownerID) {
        await addNotification(
          bangerImg: bangerImg,
          userImg: AppConstants.userImg,
          bangerId: bangerId,
          bangerOwnerId: ownerID,
          actionType: 'comment',
          userId: currentUserId,
          userName: currentUserName,
        );
        for (String token in targetToken) {
          await sender.sendNotification(
            title: "Banger Comments",
            body: "${AppConstants.userName} commentd on your banger",
            targetToken: token,
            dataPayload: {"type": "social"},
            uid: ownerID,
          );
        }
      }
    }
  }

  Future<void> addNotification({
    required String bangerId,
    required String bangerOwnerId,
    required String actionType, // 'like' / 'comment' / 'share'
    required String userId,
    required String userName,
    required String userImg, // ✅ NEW
    required String bangerImg, // ✅ NEW
  }) async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Query existing notification of same type, same banger, same owner, today
    final query =
        await firestore
            .collection('notifications')
            .where('bangerId', isEqualTo: bangerId)
            .where('bangerOwnerId', isEqualTo: bangerOwnerId)
            .where('type', isEqualTo: actionType)
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
            )
            .get();

    final userMap = {
      "uid": userId,
      "name": userName,
      "img": userImg, // ✅ NEW FIELD for user's profile image
    };

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final users = List<Map<String, dynamic>>.from(doc['users']);

      // Avoid duplicate user entry
      if (!users.any((u) => u['uid'] == userId)) {
        users.add(userMap);
        await doc.reference.update({
          "users": users,
          "timestamp": Timestamp.now(), // Update for recency
        });
      }
    } else {
      // Create new notification
      await firestore.collection('notifications').add({
        "bangerId": bangerId,
        "bangerOwnerId": bangerOwnerId,
        "type": actionType,
        "users": [userMap],
        "bangerImg": bangerImg, // ✅ NEW FIELD for banger image
        "timestamp": Timestamp.now(),
        "seenBy": [], // when creating a new notification
      });
    }
  }
}

class CommentsBottomSheet extends StatelessWidget {
  final String bangerId;
  final String currentUserId;
  final String currentUserName;
  final String ownerID;
  final String bangerImg;

  CommentsBottomSheet({
    super.key,
    required this.bangerId,
    required this.currentUserId,
    required this.currentUserName,
    required this.ownerID,
    required this.bangerImg,
  });

  late final CommentsController controller = Get.put(
    CommentsController(
      bangerId: bangerId,
      currentUserId: currentUserId,
      currentUserName: currentUserName,
      ownerID: ownerID,
      bangerImg: bangerImg,
    ),
  );

  final TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.purple,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Text('Comments', style: appThemes.Medium),
          const SizedBox(height: 10),

          Expanded(
            child: Obx(() {
              final comments = controller.comments;
              return ListView.separated(
                itemCount: comments.length,
                separatorBuilder: (_, __) => const SizedBox(),
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  final name = comment['name'] ?? 'User';
                  final text = comment['text'] ?? '';
                  final time = comment['time'] ?? '';
                  final profileImageUrl = comment['img'] ?? '';

                  final formattedTime =
                      time.isNotEmpty ? timeAgoSinceDate(time) : '';

                  return ListTile(
                    leading: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: profileImageUrl, // your image URL string
                        width: 40.w,
                        height: 40.h,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const CircleAvatar(
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                        errorWidget:
                            (context, url, error) => const CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person, color: Colors.black),
                            ),
                      ),
                    ),
                    title: Text(name, style: appThemes.small),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text,
                          style: appThemes.small.copyWith(fontFamily: 'Sans'),
                        ),
                        Text(
                          formattedTime,
                          style: TextStyle(
                            color: appColors.textGrey,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),

          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChatInputField(
                  isSending: false,
                  hint: 'Write a comment...',
                  onSend: () {
                    controller.addComment(textController.text);
                    textController.clear();
                  },
                  controller: textController,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Format ISO string to `5 min ago`
  String timeAgoSinceDate(String isoDate) {
    final date = DateTime.tryParse(isoDate)?.toLocal();
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }
}
