import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/notifications/fcm_notification_sender.dart';
import 'package:banger_drop/follow_notification.dart';
import 'package:banger_drop/views/Explore/widgets/comments_widget.dart';
import 'package:banger_drop/views/Explore/widgets/like_widget.dart';
import 'package:banger_drop/views/Notification/widgets/follow_up_widget.dart';
import 'package:banger_drop/views/Notification/widgets/notification_widget.dart';
import 'package:banger_drop/views/VideoPlayer/youtube_player.dart';
import 'package:banger_drop/views/artist_profile/artist_profile_view.dart';
import 'package:banger_drop/views/notification_setting/notification_setting_view.dart';
import 'package:banger_drop/views/playlist/playlist_view.dart';
import 'package:banger_drop/views/single_audio_player/single_player_view.dart';
import 'package:banger_drop/views/widgets/share_audio_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../Explore/widgets/share_widget.dart' show SharesBottomSheet;

class NotificationModel {
  final String docId;
  final String type;
  final String bangerId;
  final String bangerOwnerId;
  final List<Map<String, dynamic>> users;
  final DateTime timestamp;
  final String bangerImg;
  final List<String> seenBy;
  final String? status;

  NotificationModel({
    required this.docId,
    required this.type,
    required this.bangerId,
    required this.bangerOwnerId,
    required this.users,
    required this.timestamp,
    required this.bangerImg,
    required this.seenBy,
    this.status,
  });

  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      docId: doc.id,
      type: data['type'],
      bangerId: data['bangerId'] ?? '',
      bangerOwnerId: data['bangerOwnerId'],
      users: List<Map<String, dynamic>>.from(data['users']),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      bangerImg: data['bangerImg'] ?? '',
      seenBy: List<String>.from(data['seenBy'] ?? []),
      status: data['status'],
    );
  }
}

String timeAgoSinceDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
}

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Maps to track follow states for each user
  final Map<String, bool> _followStates = {};
  final Map<String, bool> _requestStates = {};
  final Map<String, bool> _loadingStates = {};

  @override
  void initState() {
    super.initState();
    markNotificationsAsSeen();
  }

  Future<void> markNotificationsAsSeen() async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('notifications')
            .where('bangerOwnerId', isEqualTo: currentUserId)
            .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final seenBy = List<String>.from(data['seenBy'] ?? []);
      if (!seenBy.contains(currentUserId)) {
        seenBy.add(currentUserId);
        batch.update(doc.reference, {'seenBy': seenBy});
      }
    }
    await batch.commit();
  }

  Future<Map<String, dynamic>?> getBangerById(String bangerId) async {
    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('Bangers')
              .doc(bangerId)
              .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        return data?..addAll({'id': docSnapshot.id});
      } else {
        print("Banger not found");
        return null;
      }
    } catch (e) {
      print("Error fetching banger: $e");
      return null;
    }
  }

  // Check if current user is following the target user
  Future<bool> _checkIfFollowing(String targetUserId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('following')
            .doc(targetUserId)
            .get();
    return doc.exists;
  }

  // Check if current user has sent a follow request to target user
  Future<bool> _checkIfRequested(String targetUserId) async {
    final query =
        await FirebaseFirestore.instance
            .collection('notifications')
            .where('type', isEqualTo: 'follow_request')
            .where('bangerOwnerId', isEqualTo: targetUserId)
            .where('status', isEqualTo: 'pending')
            .get();

    return query.docs.any((doc) {
      final users = List<Map<String, dynamic>>.from(doc['users']);
      return users.any((u) => u['uid'] == currentUserId);
    });
  }

  // Initialize follow states for a user
  Future<void> _initializeFollowState(String userId) async {
    if (_followStates.containsKey(userId)) return;

    final isFollowing = await _checkIfFollowing(userId);
    final hasRequested = await _checkIfRequested(userId);

    setState(() {
      _followStates[userId] = isFollowing;
      _requestStates[userId] = hasRequested;
      _loadingStates[userId] = false;
    });
  }
  // Updated methods for the NotificationView class

  // Send follow back (direct follow without request since they already follow you)
  Future<void> _followBackUser(String targetUserId) async {
    setState(() {
      _loadingStates[targetUserId] = true;
    });

    try {
      final now = Timestamp.now();

      // Create the mutual follow relationship directly
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .set({"timestamp": now});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId)
          .set({"timestamp": now});

      // Clean up any existing follow requests between these users
      await _removeExistingFollowRequest(targetUserId);

      setState(() {
        _followStates[targetUserId] = true;
        _requestStates[targetUserId] = false;
        _loadingStates[targetUserId] = false;
      });

      await addNotification2(
        userImg: AppConstants.userImg,
        bangerImg: '',
        bangerId: AppConstants.userId,
        bangerOwnerId: targetUserId,
        actionType: 'follow',
        userId: AppConstants.userId,
        userName: AppConstants.userName,
      );
      if (await fetchNotificationPreference('followUp', targetUserId)) {
        final targetTokens = await sender.fetchFcmTokensForUser(targetUserId);

        for (String token in targetTokens) {
          await sender.sendNotification(
            title: "New Follower",
            body: "${AppConstants.userName} started following you",
            targetToken: token,
            dataPayload: {"type": "social"},
            uid: targetUserId,
          );
        }
      }
      print("Successfully followed back user: $targetUserId");
    } catch (e) {
      print("Error following back user: $e");
      setState(() {
        _loadingStates[targetUserId] = false;
      });
    }
  }

  final FcmNotificationSender sender = FcmNotificationSender();

  Future<bool> fetchNotificationPreference(String fieldName, String uid) async {
    // final String uid = FirebaseAuth.instance.currentUser!.uid;
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

  Future<void> addNotification2({
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

    // Step 1: Delete existing 'follow' notification for the same banger
    final followQuery =
        await firestore
            .collection('notifications')
            .where('bangerId', isEqualTo: bangerId)
            .where('bangerOwnerId', isEqualTo: bangerOwnerId)
            .where('type', isEqualTo: 'follow')
            .get();

    for (final doc in followQuery.docs) {
      await doc.reference.delete();
    }

    // Step 2: Continue with regular notification logic
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
      "img": userImg, // ✅ Profile image
    };

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final users = List<Map<String, dynamic>>.from(doc['users']);

      // Avoid duplicate user entry
      if (!users.any((u) => u['uid'] == userId)) {
        users.add(userMap);
        await doc.reference.update({
          "users": users,
          "timestamp": Timestamp.now(),
        });
      }
    } else {
      // Create new notification
      await firestore.collection('notifications').add({
        "bangerId": bangerId,
        "bangerOwnerId": bangerOwnerId,
        "type": actionType,
        "users": [userMap],
        "bangerImg": bangerImg, // ✅ Banger image
        "timestamp": Timestamp.now(),
        "seenBy": [],
      });
    }
  }

  // Remove existing follow requests
  Future<void> _removeExistingFollowRequest(String profileUserId) async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('notifications')
            .where('bangerOwnerId', isEqualTo: profileUserId)
            .where('type', isEqualTo: 'follow_request')
            .get();

    for (final doc in querySnapshot.docs) {
      final users = List<Map<String, dynamic>>.from(doc['users']);
      final updatedUsers =
          users.where((u) => u['uid'] != currentUserId).toList();

      if (updatedUsers.length != users.length) {
        if (updatedUsers.isEmpty) {
          await doc.reference.delete();
        } else {
          await doc.reference.update({'users': updatedUsers});
        }
      }
    }
  }

  // // Send follow request (similar to your sendFollowRequestToggle function)
  // Future<void> _sendFollowRequest(String targetUserId) async {
  //   setState(() {
  //     _loadingStates[targetUserId] = true;
  //   });

  //   try {
  //     // Check if already following
  //     final isFollowing = await _checkIfFollowing(targetUserId);
  //     if (isFollowing) {
  //       setState(() {
  //         _followStates[targetUserId] = true;
  //         _requestStates[targetUserId] = false;
  //         _loadingStates[targetUserId] = false;
  //       });
  //       return;
  //     }

  //     // Check if request already sent
  //     final hasRequested = await _checkIfRequested(targetUserId);
  //     if (hasRequested) {
  //       setState(() {
  //         _requestStates[targetUserId] = true;
  //         _loadingStates[targetUserId] = false;
  //       });
  //       return;
  //     }

  //     // Send follow request notification
  //     await FirebaseFirestore.instance.collection('notifications').add({
  //       "bangerId": "",
  //       "bangerOwnerId": targetUserId,
  //       "type": "follow_request",
  //       "users": [
  //         {
  //           "uid": currentUserId,
  //           "name": AppConstants.userName,
  //           "img": AppConstants.userImg,
  //         },
  //       ],
  //       "bangerImg": "",
  //       "timestamp": Timestamp.now(),
  //       "status": "pending",
  //       "seenBy": [],
  //     });

  //     setState(() {
  //       _requestStates[targetUserId] = true;
  //       _loadingStates[targetUserId] = false;
  //     });

  //     // TODO: Send FCM notification if user has followUp notifications enabled
  //     // You can implement this similar to your original code
  //   } catch (e) {
  //     print("Error sending follow request: $e");
  //     setState(() {
  //       _loadingStates[targetUserId] = false;
  //     });
  //   }
  // }

  // Updated follow button widget
  Widget _buildFollowButton(String userId) {
    // Initialize state if not already done
    if (!_followStates.containsKey(userId)) {
      _initializeFollowState(userId);
      return const SizedBox(
        width: 80,
        height: 32,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final isFollowing = _followStates[userId] ?? false;
    final hasRequested = _requestStates[userId] ?? false;
    final isLoading = _loadingStates[userId] ?? false;

    if (isLoading) {
      return const SizedBox(
        width: 80,
        height: 32,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    String buttonText;
    Color buttonColor;
    VoidCallback? onTap;

    if (isFollowing) {
      buttonText = "Following";
      buttonColor = Colors.grey;
      onTap = null; // Disable tap - already following
    } else {
      // Since this is for accepted follow requests, they already follow you
      // So we can directly follow them back without sending a request
      buttonText = "Follow Back";
      buttonColor = appColors.purple;
      onTap = () => _followBackUser(userId);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/Picture1.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 50),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Notifications",
                            style: appThemes.Large.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Get.to(() => NotificationsScreen()),
                            child: Text(
                              "Filter",
                              style: appThemes.Large.copyWith(
                                color: appColors.textGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('notifications')
                                .where(
                                  'bangerOwnerId',
                                  isEqualTo: currentUserId,
                                )
                                .orderBy('timestamp', descending: true)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text(
                                "No notifications yet",
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }

                          final docs =
                              snapshot.data!.docs
                                  .map((doc) => NotificationModel.fromDoc(doc))
                                  .toList();
                          final followRequests =
                              docs
                                  .where((n) => n.type == 'follow_request')
                                  .toList();
                          final otherNotifications =
                              docs
                                  .where((n) => n.type != 'follow_request')
                                  .toList();

                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                //  NewNotificationScreen
                                // Padding(
                                //   padding: const EdgeInsets.symmetric(
                                //     horizontal: 10,
                                //     vertical: 8,
                                //   ),
                                //   child: Text(
                                //     "Other Notifications",
                                //     style: appThemes.Large.copyWith(
                                //       fontWeight: FontWeight.bold,
                                //       color: Colors.white,
                                //     ),
                                //   ),
                                // ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: otherNotifications.length,
                                  itemBuilder: (context, index) {
                                    final item = otherNotifications[index];
                                    final firstUser = item.users.first['name'];
                                    final firstUserImg =
                                        item.users.first['img'] ?? '';
                                    final othersCount = item.users.length - 1;
                                    final title =
                                        othersCount > 0
                                            ? '$firstUser, $othersCount other${othersCount > 1 ? 's' : ''}'
                                            : firstUser;
                                    final subtitle =
                                        (() {
                                          switch (item.type) {
                                            case 'like':
                                              return 'Liked your banger';
                                            case 'comment':
                                              return 'Commented your banger';
                                            case 'share':
                                              return 'Shared your banger';
                                            case 'Playlist_like':
                                              return 'Liked your Playlist';
                                            case 'Playlistcomment':
                                              return 'Commented on your Playlist';
                                            case 'follow':
                                              return 'started following you';
                                            default:
                                              return 'Sent you a notification';
                                          }
                                        })();

                                    return GestureDetector(
                                      onTap: () async {
                                        if (item.type == 'Playlist_like' ||
                                            item.type == 'Playlistcomment') {
                                          Get.to(
                                            () => PlaylistView(
                                              playlistId: item.bangerId,
                                            ),
                                          );
                                        } else if (item.type == 'follow') {
                                          Get.to(
                                            () => ArtistProfileView(
                                              userId: item.bangerId,
                                            ),
                                          );
                                        } else {
                                          final bangerData =
                                              await getBangerById(
                                                item.bangerId,
                                              );
                                          print(bangerData?['id']);
                                          if (bangerData?['youtubeSong'] ==
                                              true) {
                                            var link =
                                                bangerData?['audioUrl'] ?? '';
                                            if (bangerData?['isRawLink'] ==
                                                true) {
                                              link =
                                                  YoutubePlayer.convertUrlToId(
                                                    link,
                                                  );
                                            }
                                            Get.to(
                                              () => YoutubePlayerScreen(
                                                videoUrl: link ?? '',
                                                bangerId: bangerData?['id'],
                                                ownerID:
                                                    bangerData?['CreatedBy'] ??
                                                    '',
                                                currentUserId:
                                                    AppConstants.userId,
                                                bangerImg:
                                                    bangerData?['imageUrl'] ??
                                                    '',
                                                artistImageUrl: '',
                                                songImageUrl:
                                                    bangerData?['imageUrl'] ??
                                                    '',
                                                artistName: '',
                                                songName:
                                                    bangerData?['title'] ?? '',
                                                playlistName:
                                                    bangerData?['playlistName'] ==
                                                            'Select'
                                                        ? ''
                                                        : bangerData?['playlistName'] ??
                                                            '',
                                                timeAgo:
                                                    getTimeAgoFromTimestamp(
                                                      bangerData?['createdAt'],
                                                    ),
                                                comments:
                                                    bangerData?['TotalComments'] ??
                                                    0,
                                                shares:
                                                    bangerData?['TotalShares'] ??
                                                    0,
                                                playlistDropped:
                                                    bangerData?['playlistName'] !=
                                                    'Select',
                                                onCommentTap:
                                                    () => Get.bottomSheet(
                                                      CommentsBottomSheet(
                                                        bangerImg:
                                                            bangerData?['imageUrl'] ??
                                                            '',
                                                        ownerID:
                                                            bangerData?['CreatedBy'] ??
                                                            '',
                                                        bangerId:
                                                            bangerData?['id'],
                                                        currentUserId:
                                                            AppConstants.userId,
                                                        currentUserName:
                                                            AppConstants
                                                                .userName,
                                                      ),
                                                      isScrollControlled: true,
                                                    ),

                                                onShareTap: () {
                                                  showAudioShareBottomSheet(
                                                    img:
                                                        bangerData?['imageUrl'],

                                                    audioUrl:
                                                        bangerData?['audioUrl'] ??
                                                        '',
                                                    title: bangerData?['title'],
                                                    description:
                                                        bangerData?['description'],
                                                    bangerId: bangerData?['id'],
                                                  );
                                                },
                                                onLikeInfoTap: () async {
                                                  final doc =
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection('Bangers')
                                                          .doc(
                                                            bangerData?['id'],
                                                          )
                                                          .get();
                                                  if (doc.exists) {
                                                    final data = doc.data()!;
                                                    final List<
                                                      Map<String, dynamic>
                                                    >
                                                    likes = List<
                                                      Map<String, dynamic>
                                                    >.from(data['Likes'] ?? []);
                                                    Get.bottomSheet(
                                                      LikesBottomSheet(
                                                        likeMaps: likes,
                                                      ),
                                                      isScrollControlled: true,
                                                    );
                                                  }
                                                },
                                                onshareInfoTap: () {
                                                  Get.bottomSheet(
                                                    SharesBottomSheet(
                                                      bangerId:
                                                          bangerData?['id'],
                                                    ),
                                                    isScrollControlled: true,
                                                  );
                                                },
                                                ProfileTap: () {
                                                  Get.to(
                                                    () => ArtistProfileView(
                                                      userId:
                                                          bangerData?['CreatedBy'] ??
                                                          '',
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
                                            return;
                                          }
                                          Get.to(
                                            () => SingleBangerPlayerView(
                                              bangers: [bangerData],
                                              currentIndex: index,
                                            ),
                                          );
                                        }
                                      },
                                      child: NotificationTile(
                                        leadingImageUrl: firstUserImg,
                                        title: title,
                                        subtitle: subtitle,
                                        timeAgo: timeAgoSinceDate(
                                          item.timestamp,
                                        ),
                                        showTrailingImage:
                                            item.type == 'follow'
                                                ? false
                                                : true,
                                        trailingImageUrl: item.bangerImg,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String getTimeAgoFromTimestamp(Timestamp timestamp) {
    final time = timestamp.toDate();
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30)
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
    final years = (diff.inDays / 365).floor();
    return '$years year${years > 1 ? 's' : ''} ago';
  }
}
