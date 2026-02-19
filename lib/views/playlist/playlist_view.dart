import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/notifications/fcm_notification_sender.dart';
import 'package:banger_drop/views/Explore/widgets/comments_widget.dart';
import 'package:banger_drop/views/Explore/widgets/like_widget.dart';
import 'package:banger_drop/views/Explore/widgets/share_widget.dart';
import 'package:banger_drop/views/VideoPlayer/youtube_player.dart';
import 'package:banger_drop/views/artist_profile/artist_profile_view.dart';
import 'package:banger_drop/views/playlist/controller/playlistView_controller.dart';
import 'package:banger_drop/views/playlist/widgets/music_widget.dart';
import 'package:banger_drop/views/playlist/widgets/playlis_appbar_widget.dart';
import 'package:banger_drop/views/playlist/widgets/playlist_comment_sheet.dart';
import 'package:banger_drop/views/playlist/widgets/playlist_info_widget.dart';
import 'package:banger_drop/views/single_audio_player/single_player_view.dart';
import 'package:banger_drop/views/widgets/loading_widget.dart';
import 'package:banger_drop/views/widgets/share_audio_widget.dart';
import 'package:banger_drop/views/widgets/share_playlist_widget.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PlaylistView extends StatefulWidget {
  const PlaylistView({super.key, required this.playlistId});
  final String playlistId;

  @override
  State<PlaylistView> createState() => _PlaylistViewState();
}

class _PlaylistViewState extends State<PlaylistView> {
  final controller = Get.put(PlaylistDetailController());

  final isLiked = false.obs;
  bool isLiking = false;

  @override
  void initState() {
    super.initState();
    AppConstants.initializeUserData();
    controller.fetchPlaylistById(widget.playlistId);
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

  Future<void> _toggleLike() async {
    if (isLiking) return;
    isLiking = true;

    final ref = FirebaseFirestore.instance
        .collection('Playlist')
        .doc(widget.playlistId);

    bool sendNotification = false;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final likes = List<Map<String, dynamic>>.from(data['Likes'] ?? []);
      int totalLikes = data['TotalLikes'] ?? 0;

      final alreadyLiked = likes.any(
        (like) => like['id'] == AppConstants.userId,
      );

      if (alreadyLiked) {
        // Unlike
        likes.removeWhere((like) => like['id'] == AppConstants.userId);
        totalLikes = (totalLikes > 0) ? totalLikes - 1 : 0;
        isLiked.value = false;
        sendNotification = false; // Do not notify on unlike
      } else {
        // Like
        likes.add({
          'id': AppConstants.userId,
          'name': AppConstants.userName,
          'img': AppConstants.userImg,
          'time': DateTime.now().toIso8601String(),
        });
        totalLikes++;
        isLiked.value = true;
        sendNotification = true; // Notify on like
      }

      transaction.update(ref, {'Likes': likes, 'TotalLikes': totalLikes});
    });

    isLiking = false;

    // ✅ Notify only if it was a like action
    if (sendNotification &&
        await fetchNotificationPreference(
          'social',
          controller.playlistData['created By'],
        )) {
      final ownerId = controller.playlistData['created By'];

      if (AppConstants.userId != ownerId) {
        final targetTokens = await sender.fetchFcmTokensForUser(ownerId);

        await addNotification(
          userImg: AppConstants.userImg,
          bangerImg: controller.playlistData['image'] ?? '',
          bangerId: controller.playlistData['id'],
          bangerOwnerId: ownerId,
          actionType: 'Playlist_like',
          userId: AppConstants.userId,
          userName: AppConstants.userName,
        );

        for (String token in targetTokens) {
          await sender.sendNotification(
            title: "Playlist Liked ❤️",
            body: "${AppConstants.userName} liked your playlist",
            targetToken: token,
            dataPayload: {"type": "social"},
            uid: ownerId,
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
    try {
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
    } catch (e) {
      print(e);
    }
  }

  void _showLikesInfo() {
    Get.bottomSheet(
      StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('Playlist')
                .doc(widget.playlistId)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List<Map<String, dynamic>> likes =
              List<Map<String, dynamic>>.from(data['Likes'] ?? []);

          return LikesBottomSheet(likeMaps: likes);
        },
      ),
      isScrollControlled: true,
    );
  }

  void _showSharesInfo() {
    Get.bottomSheet(
      SharesBottomSheet(bangerId: widget.playlistId),
      isScrollControlled: true,
    );
  }

  void _showCommentsBottomSheet(String ownerID) {
    Get.bottomSheet(
      PlaylistCommentsBottomSheet(
        playlistId: widget.playlistId,
        currentUserId: AppConstants.userId,
        currentUserName: AppConstants.userName,
        currentUserImg: AppConstants.userImg,
        ownerId: ownerID,
        playlistImg: controller.playlistData['image'],
        playlistName: controller.playlistData['title'],
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColors.purple,
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: LoadingWidget(color: appColors.white));
        }

        if (controller.error.isNotEmpty) {
          return Center(
            child: Text(controller.error.value, style: appThemes.Medium),
          );
        }

        final data = controller.playlistData;
        final bangers = data['bangers'];

        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/Picture1.png',
                fit: BoxFit.cover,
              ),
            ),
            ListView.builder(
              itemCount: bangers.length,
              padding: EdgeInsets.only(top: 350.h),
              itemBuilder: (context, index) {
                return Music(
                  bangerId: bangers[index]['id'] ?? '',
                  onshareTap: () {
                    showAudioShareBottomSheet(
                      img: bangers[index]['imageUrl'] ?? '',
                      audioUrl: bangers[index]['audioUrl'] ?? '',
                      title: bangers[index]['title'],
                      description: '',
                      bangerId: bangers[index]['id'],
                    );
                  },
                  // Replace your existing onTap callback in the ListView.builder with this:
                  onTap: () async {
                    // Add null safety checks
                    final bangerId = bangers[0]['id'];
                    print(bangers);
                    if (bangerId == null || bangerId.isEmpty) {
                      print('Error: Banger ID is null or empty');
                      return;
                    }

                    final bangerData = await getBangerById(bangerId);
                    if (bangerData == null) {
                      print('Error: Could not fetch banger data');
                      return;
                    }

                    if (bangerData['youtubeSong'] == true) {
                      var link = bangerData['audioUrl'] ?? '';
                      if (bangerData['isRawLink'] == true) {
                        link = YoutubePlayer.convertUrlToId(link);
                      }
                      Get.to(
                        () => YoutubePlayerScreen(
                          isPlaylist: true,
                          playlistId: widget.playlistId,
                          videoUrl: link ?? '',
                          bangerId: bangerData['id'] ?? '',
                          ownerID: bangerData['CreatedBy'] ?? '',
                          currentUserId: AppConstants.userId,
                          bangerImg: bangerData['imageUrl'] ?? '',
                          artistImageUrl: '',
                          songImageUrl: bangerData['imageUrl'] ?? '',
                          artistName: '',
                          songName: bangerData['title'] ?? '',
                          playlistName:
                              bangerData['playlistName'] == 'Select'
                                  ? ''
                                  : bangerData['playlistName'] ?? '',
                          timeAgo: getTimeAgoFromTimestamp(
                            bangerData['createdAt'],
                          ),
                          comments: bangerData['TotalComments'] ?? 0,
                          shares: bangerData['TotalShares'] ?? 0,
                          playlistDropped:
                              bangerData['playlistName'] != 'Select',
                          onCommentTap:
                              () => Get.bottomSheet(
                                CommentsBottomSheet(
                                  bangerImg: bangerData['imageUrl'] ?? '',
                                  ownerID: bangerData['CreatedBy'] ?? '',
                                  bangerId: bangerData['id'] ?? '',
                                  currentUserId: AppConstants.userId,
                                  currentUserName: AppConstants.userName,
                                ),
                                isScrollControlled: true,
                              ),
                          onShareTap: () {
                            showAudioShareBottomSheet(
                              img: bangers[index]['imageUrl'] ?? '',
                              audioUrl: bangerData['audioUrl'] ?? '',
                              title: bangerData['title'] ?? '',
                              description: bangerData['description'] ?? '',
                              bangerId: bangerData['id'] ?? '',
                            );
                          },
                          onLikeInfoTap: () async {
                            final doc =
                                await FirebaseFirestore.instance
                                    .collection('Bangers')
                                    .doc(bangerData['id'])
                                    .get();
                            if (doc.exists) {
                              final data = doc.data()!;
                              final List<Map<String, dynamic>> likes =
                                  List<Map<String, dynamic>>.from(
                                    data['Likes'] ?? [],
                                  );
                              Get.bottomSheet(
                                LikesBottomSheet(likeMaps: likes),
                                isScrollControlled: true,
                              );
                            }
                          },
                          onshareInfoTap: () {
                            Get.bottomSheet(
                              SharesBottomSheet(
                                bangerId: bangerData['id'] ?? '',
                              ),
                              isScrollControlled: true,
                            );
                          },
                          ProfileTap: () {
                            Get.to(
                              () => ArtistProfileView(
                                userId: bangerData['CreatedBy'] ?? '',
                              ),
                            );
                          },
                        ),
                      );
                      return;
                    }
                    Get.to(
                      () => SingleBangerPlayerView(
                        bangers: bangers,
                        currentIndex: index,
                      ),
                    );
                  },
                  title: bangers[index]['title'],
                  artist: bangers[index]['artist'],
                  imageUrl: bangers[index]['imageUrl'],
                );
              },
            ),
            ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30.r),
                bottomRight: Radius.circular(30.r),
              ),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: data['image'],
                    height: 300.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Center(
                          child: LoadingWidget(color: appColors.white),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          color: Colors.grey[800],
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                  ),
                  Positioned(
                    top: 50.h,
                    width: MediaQuery.of(context).size.width,
                    child: PlaylisAppbarWidget(
                      id: widget.playlistId,
                      onBackPressed: () => Get.back(),
                      onSharePressed:
                          () => showPlaylistShareBottomSheet(
                            playlistId: widget.playlistId,
                            title: data['title'],
                            imageUrl: data['image'],
                          ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    width: MediaQuery.of(context).size.width,
                    child: PlaylistInfoWidget(
                      description: data['description'],
                      onPlayPress: () async {
                        if (bangers.isEmpty) return;
                        // print(bangers[0]['id']);
                        final bangerData = await getBangerById(
                          bangers[0]['id'],
                        );
                        print(bangerData?['youtubeSong']);
                        if (bangerData?['youtubeSong'] == true) {
                          var link = bangerData?['audioUrl'] ?? '';
                          if (bangerData?['isRawLink'] == true) {
                            link = YoutubePlayer.convertUrlToId(link);
                          }
                          Get.to(
                            () => YoutubePlayerScreen(
                              isPlaylist: true,
                              playlistId: widget.playlistId,
                              videoUrl: link ?? '',
                              bangerId: bangerData?['id'],
                              ownerID: bangerData?['CreatedBy'] ?? '',
                              currentUserId: AppConstants.userId,
                              bangerImg: bangerData?['imageUrl'] ?? '',
                              artistImageUrl: '',
                              songImageUrl: bangerData?['imageUrl'] ?? '',
                              artistName: '',
                              songName: bangerData?['title'] ?? '',
                              playlistName:
                                  bangerData?['playlistName'] == 'Select'
                                      ? ''
                                      : bangerData?['playlistName'] ?? '',
                              timeAgo: getTimeAgoFromTimestamp(
                                bangerData?['createdAt'],
                              ),
                              comments: bangerData?['TotalComments'] ?? 0,
                              shares: bangerData?['TotalShares'] ?? 0,
                              playlistDropped:
                                  bangerData?['playlistName'] != 'Select',
                              onCommentTap:
                                  () => Get.bottomSheet(
                                    CommentsBottomSheet(
                                      bangerImg: bangerData?['imageUrl'] ?? '',
                                      ownerID: bangerData?['CreatedBy'] ?? '',
                                      bangerId: bangerData?['id'],
                                      currentUserId: AppConstants.userId,
                                      currentUserName: AppConstants.userName,
                                    ),
                                    isScrollControlled: true,
                                  ),

                              onShareTap: () {
                                showAudioShareBottomSheet(
                                  img: bangerData?['imageUrl'] ?? '',

                                  audioUrl: bangerData?['audioUrl'] ?? '',
                                  title: bangerData?['title'],
                                  description: bangerData?['description'],
                                  bangerId: bangerData?['id'],
                                );
                              },
                              onLikeInfoTap: () async {
                                final doc =
                                    await FirebaseFirestore.instance
                                        .collection('Bangers')
                                        .doc(bangerData?['id'])
                                        .get();
                                if (doc.exists) {
                                  final data = doc.data()!;
                                  final List<Map<String, dynamic>> likes =
                                      List<Map<String, dynamic>>.from(
                                        data['Likes'] ?? [],
                                      );
                                  Get.bottomSheet(
                                    LikesBottomSheet(likeMaps: likes),
                                    isScrollControlled: true,
                                  );
                                }
                              },
                              onshareInfoTap: () {
                                Get.bottomSheet(
                                  SharesBottomSheet(
                                    bangerId: bangerData?['id'],
                                  ),
                                  isScrollControlled: true,
                                );
                              },
                              ProfileTap: () {
                                Get.to(
                                  () => ArtistProfileView(
                                    userId: bangerData?['CreatedBy'] ?? '',
                                  ),
                                );
                              },
                            ),
                          );
                          return;
                        }

                        Get.to(
                          () => SingleBangerPlayerView(
                            bangers: bangers,
                            currentIndex: 0,
                          ),
                        );
                      },
                      name: data['title'],
                      artist: data['authorName'],
                      id: widget.playlistId,
                      isPlaylist: true,
                      onSharePressed:
                          () => showPlaylistShareBottomSheet(
                            playlistId: widget.playlistId,
                            title: data['title'],
                            imageUrl: data['image'],
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 310.h, left: 12.w, right: 12.w),
              child: StreamBuilder<DocumentSnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('Playlist')
                        .doc(widget.playlistId)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();

                  final data =
                      snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  final likes = List<Map<String, dynamic>>.from(
                    data['Likes'] ?? [],
                  );
                  final totalLikes = data['TotalLikes'] ?? 0;
                  final totalShares = data['TotalShares'] ?? 0;

                  isLiked.value = likes.any(
                    (like) => like['id'] == AppConstants.userId,
                  );

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              _showCommentsBottomSheet(
                                controller.playlistData['created By'],
                              );
                            },
                            icon: const Icon(
                              Icons.chat_bubble_outline_outlined,
                              color: Colors.black,
                            ),
                          ),
                          Obx(
                            () => IconButton(
                              onPressed: _toggleLike,
                              icon: Icon(
                                isLiked.value
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color:
                                    isLiked.value ? Colors.red : Colors.black,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _showLikesInfo,
                            child: Text(
                              '$totalLikes likes',
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
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
        return data?..addAll({'id': docSnapshot.id}); // Include the document ID
      } else {
        print("Banger not found");
        return null;
      }
    } catch (e) {
      print("Error fetching banger: $e");
      return null;
    }
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
