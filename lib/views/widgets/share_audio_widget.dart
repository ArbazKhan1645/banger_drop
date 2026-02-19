import 'dart:io';

import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/notifications/fcm_notification_sender.dart';
import 'package:banger_drop/views/widgets/loading_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:banger_drop/views/chat/controller/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AudioShareController extends GetxController {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  var users = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  final isUploadingStory = false.obs;
  final isReposting = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    isLoading.value = true;

    final firestore = FirebaseFirestore.instance;

    try {
      // 🔽 Get list of follower and following user IDs
      final followersSnapshot =
          await firestore
              .collection('users')
              .doc(currentUserId)
              .collection('followers')
              .get();

      final followingSnapshot =
          await firestore
              .collection('users')
              .doc(currentUserId)
              .collection('following')
              .get();

      final followerIds = followersSnapshot.docs.map((doc) => doc.id).toSet();
      final followingIds = followingSnapshot.docs.map((doc) => doc.id).toSet();

      final allUserIds = {...followerIds, ...followingIds}.toList();

      // 🔃 Split userIds into chunks of 30
      List<List<String>> chunks = [];
      const chunkSize = 30;
      for (var i = 0; i < allUserIds.length; i += chunkSize) {
        chunks.add(
          allUserIds.sublist(
            i,
            i + chunkSize > allUserIds.length
                ? allUserIds.length
                : i + chunkSize,
          ),
        );
      }

      List<Map<String, dynamic>> fetchedUsers = [];

      for (var chunk in chunks) {
        final querySnapshot =
            await firestore
                .collection('users')
                .where(FieldPath.documentId, whereIn: chunk)
                .get();

        fetchedUsers.addAll(
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Unknown',
              'img': data.containsKey('img') ? data['img'] : '',
            };
          }),
        );
      }

      users.value = fetchedUsers;
    } catch (e) {
      print('Error fetching followers/followings: $e');
      Get.snackbar('Error', 'Could not load users.');
    }

    isLoading.value = false;
  }

  Future<void> pickAndUploadStory(audioUrl) async {
    isUploadingStory.value = true;

    try {
      // final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      // final ref = FirebaseStorage.instance.ref().child('stories/$fileName');

      // await ref.putFile(File(filePath));
      // final downloadUrl = await ref.getDownloadURL();

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .get();
      final userData = userDoc.data() ?? {};

      await FirebaseFirestore.instance
          .collection('stories')
          .doc(currentUserId)
          .set({
            'uid': currentUserId,
            'url': audioUrl,
            'type': 'audio',
            'createdAt': Timestamp.now(),
            'img': userData['img'] ?? '',
            'name': userData['name'] ?? 'User',
          });

      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }

      if (Get.isBottomSheetOpen ?? false) {
        Get.back();
      }

      Get.snackbar('Success', 'Story uploaded successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload story');
    } finally {
      isUploadingStory.value = false;
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

  Future<void> RepostBanger(String bangerID) async {
    isReposting.value = true;
    final String newId = DateTime.now().microsecondsSinceEpoch.toString();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      final bangerRef = FirebaseFirestore.instance
          .collection("Bangers")
          .doc(bangerID);
      final userRef = FirebaseFirestore.instance
          .collection("users")
          .doc(currentUserId);

      final docSnapshot = await bangerRef.get();
      if (!docSnapshot.exists) {
        isReposting.value = false;
        Get.snackbar('Failed', 'Original banger not found.');
        return;
      }

      final data = docSnapshot.data()!;
      final createdBy = data['CreatedBy'];
      final bangerShares = List<Map<String, dynamic>>.from(
        data['shares'] ?? [],
      );

      // ✅ Count how many times this user already shared
      final userShares =
          bangerShares.where((s) => s['userId'] == currentUserId).length;
      if (userShares >= 10) {
        isReposting.value = false;
        Get.snackbar(
          'Notice',
          'You have already reposted this banger 10 times.',
        );
        return;
      }

      // ✅ Create new reposted banger
      await FirebaseFirestore.instance.collection("Bangers").doc(newId).set({
        ...data,
        'TotalLikes': 0,
        'Totalcomments': 0,
        'TotalShares': 0,
        'plays': 0,
        'comments': [],
        'Likes': [],
        'shares': [],
        'createdAt': FieldValue.serverTimestamp(),
        'CreatedBy': currentUserId,
        'id': newId,
        'UserImage': AppConstants.userImg,
        'Repost': true,
        'Owner': createdBy,
      });

      // ✅ Add share entry
      final now = Timestamp.now();
      await bangerRef.update({
        'TotalShares': FieldValue.increment(1),
        'shares': FieldValue.arrayUnion([
          {
            'userId': currentUserId,
            'name': AppConstants.userName,
            'sharedAt': now,
            'userImg': AppConstants.userImg ?? '',
          },
        ]),
      });

      /// 🔥 POINT SYSTEM LOGIC STARTS HERE 🔥
      final creatorRef = FirebaseFirestore.instance
          .collection('users')
          .doc(createdBy);
      final updatedSnapshot = await bangerRef.get();
      final updatedData = updatedSnapshot.data()!;
      final updatedShares = List<Map<String, dynamic>>.from(
        updatedData['shares'] ?? [],
      );
      final totalShares = updatedShares.length;

      int pointsToAdd = 0;

      // ➤ A. Same user share milestone
      final newUserShareCount = userShares + 1;
      if (newUserShareCount == 1)
        pointsToAdd += 5;
      else if (newUserShareCount == 5)
        pointsToAdd += 25;
      else if (newUserShareCount == 10)
        pointsToAdd += 50;

      // ➤ B. Total share milestones
      if (totalShares == 10)
        pointsToAdd += 10;
      else if (totalShares == 50)
        pointsToAdd += 75;
      else if (totalShares == 100)
        pointsToAdd += 100;

      // ➤ C. Every 100 shares
      if (totalShares % 100 == 0) pointsToAdd += 100;

      // ✅ Add points to creator
      if (pointsToAdd > 0 && createdBy != currentUserId) {
        await creatorRef.set({
          'points': FieldValue.increment(pointsToAdd),
          'pointsHistory': FieldValue.arrayUnion([
            {
              'points': pointsToAdd,
              'reason': 'banger_reposted',
              'bangerId': bangerID,
              'timestamp': now,
            },
          ]),
        }, SetOptions(merge: true));
      }

      if (await fetchNotificationPreference('social', createdBy)) {
        final targetToken = await sender.fetchFcmTokensForUser(createdBy);
        if (AppConstants.userId != createdBy) {
          await addNotification(
            isPlayList: false,
            bangerImg: data['imageUrl'],
            userImg: AppConstants.userImg,
            bangerId: bangerID,
            bangerOwnerId: createdBy ?? '',
            actionType: 'share',
            userId: AppConstants.userId,
            userName: AppConstants.userName,
          );
        }
        // 🔔 Add notification

        for (String token in targetToken) {
          await sender.sendNotification(
            title: "Banger shared",
            body: "${AppConstants.userName} shared your banger",
            targetToken: token,
            dataPayload: {"type": "social"},
            uid: createdBy,
          );
        }
      }

      isReposting.value = false;
      Get.back();
      Get.snackbar('Success', 'Banger Reposted Successfully');
    } catch (e) {
      isReposting.value = false;
      debugPrint('Repost Error: $e');
      Get.snackbar('Error', 'Error reposting banger. Please try again.');
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
  required bool isPlayList, // ✅ NEW
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
      'isPlayList': isPlayList, // ✅ NEW FIELD for playlist
      "bangerOwnerId": bangerOwnerId,
      "type": actionType,
      "users": [userMap],
      "bangerImg": bangerImg, // ✅ NEW FIELD for banger image
      "timestamp": Timestamp.now(),
      "seenBy": [], // when creating a new notification
    });
  }
}

void showAudioShareBottomSheet({
  required String audioUrl,
  required String title,
  required String description,
  required String bangerId,
  required String img,
}) {
  final controller = Get.put(AudioShareController());

  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SizedBox(
        height: ScreenUtil().screenHeight * .6,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Send Audio To...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // 🔼 Add to Story and Repost Row
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  controller.isUploadingStory.value
                      ? LoadingWidget(color: appColors.black)
                      : GestureDetector(
                        onTap: () {
                          controller.pickAndUploadStory(audioUrl);
                        },
                        child: Column(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.pink[100],
                              child: Icon(
                                Icons.add_circle_outline,
                                color: Colors.pink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Story',
                              style: appThemes.small.copyWith(
                                fontFamily: 'Sans',
                                color: appColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                  SizedBox(width: 20),
                  controller.isReposting.value
                      ? LoadingWidget(color: appColors.black)
                      : GestureDetector(
                        onTap: () {
                          controller.RepostBanger(bangerId);
                        },
                        child: Column(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Icon(Icons.repeat, color: Colors.blue),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Repost',
                              style: appThemes.small.copyWith(
                                fontFamily: 'Sans',
                                color: appColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),

              // 🔽 List of Users to Share Audio
              Expanded(
                child: ListView.builder(
                  itemCount: controller.users.length,
                  itemBuilder: (_, index) {
                    final user = controller.users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            user['img'].isNotEmpty
                                ? NetworkImage(user['img'])
                                : null,
                        child:
                            user['img'].isEmpty
                                ? const Icon(Icons.person)
                                : null,
                      ),
                      title: Text(user['name']),
                      onTap: () {
                        final chatController = Get.put(ChatController());
                        chatController.sendAudioMessage(
                          receiverId: user['id'],
                          audioUrl: audioUrl,
                          title: title,
                          description: description,
                          bangerId: bangerId,
                          img: img,
                        );
                        Get.back(); // Close bottom sheet
                      },
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    ),
    isScrollControlled: true,
  );
}
