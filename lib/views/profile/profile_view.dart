import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/Explore/widgets/comments_widget.dart';
import 'package:banger_drop/views/Explore/widgets/like_widget.dart';
import 'package:banger_drop/views/Explore/widgets/playlist_builder_widget.dart';
import 'package:banger_drop/views/VideoPlayer/youtube_player.dart';
import 'package:banger_drop/views/artist_profile/artist_profile_view.dart';
import 'package:banger_drop/views/artist_profile/widgets/info_widget.dart';
import 'package:banger_drop/views/playlist/playlist_view.dart';
import 'package:banger_drop/views/playlist/widgets/music_widget.dart';
import 'package:banger_drop/views/profile/controllers/profile_controller.dart';
import 'package:banger_drop/views/settings/settings_view.dart';
import 'package:banger_drop/views/single_audio_player/single_player_view.dart';
import 'package:banger_drop/views/widgets/share_audio_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:banger_drop/views/Explore/widgets/share_widget.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileViewController controller;

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    controller = Get.put(ProfileViewController(userId));
    controller.checkIfFollowing(userId); // Pass the viewed user's ID
    controller.listenToFollowCounts(userId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/images/Picture1.png',
                ), // Replace with your image path
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final user = controller.userData.value;
              if (user == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("User not found", style: appThemes.small),
                      IconButton(
                        onPressed: () {
                          Get.to(() => SettingsScreen());
                        },
                        icon: Icon(Icons.settings, color: appColors.white),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await controller.fetchData();
                },
                child: SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(), // 👈 Add this line

                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Settings button

                      // Dynamic user info
                      ProfileInfoWidget(
                        uid: '0',
                        hasRequested: false,
                        imgUrl: user['img'] ?? '',
                        name: user['name'] ?? 'Unknown',
                        points: user['points'] ?? 0,
                        followers: controller.followersCount.value,
                        following: controller.followingCount.value,

                        isFollowing: controller.isFollowing.value,
                        onFollowToggle:
                            () => controller.toggleFollow(
                              FirebaseAuth.instance.currentUser!.uid,
                            ),
                        onFollowersTap:
                            () => controller.showFollowersDialog(
                              FirebaseAuth.instance.currentUser!.uid,
                            ),
                        onFollowingTap:
                            () => controller.showFollowingDialog(
                              FirebaseAuth.instance.currentUser!.uid,
                            ),
                        showSetting: true,
                        showFollowButton: false,
                      ),

                      const SizedBox(height: 10),

                      // Playlist heading
                      Text(
                        "Playlist",
                        style: appThemes.Large.copyWith(
                          fontSize: 23.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Playlist content
                      if (controller.playlists.isEmpty)
                        Text("No playlists available", style: appThemes.small)
                      else
                        Obx(() {
                          final playlists = controller.playlists;

                          if (playlists.isEmpty) {
                            return const Center(
                              child: Text("No playlists found"),
                            );
                          }

                          return SizedBox(
                            height:
                                190.h, // Adjust this height based on PlaylistBuilder size
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: playlists.length,
                              itemBuilder: (context, index) {
                                final doc = playlists[index];
                                final data = doc.data() as Map<String, dynamic>;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ), // spacing
                                  child: GestureDetector(
                                    onLongPress: () {
                                      controller.showDeletePlaylistDialog(
                                        context,
                                        doc.id,
                                      );
                                    },
                                    child: PlaylistBuilder(
                                      playlistId: doc.id,
                                      imageUrl: data['image'] ?? '',
                                      playlistName: data['title'] ?? 'No Title',
                                      artistName:
                                          data['authorName'] ??
                                          'Unknown Artist',
                                      ontap:
                                          () => Get.to(
                                            () => PlaylistView(
                                              playlistId: doc.id,
                                            ),
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),

                      // Bangers heading
                      Text(
                        "Bangers dropped",
                        style: appThemes.Large.copyWith(
                          fontSize: 23.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // List of bangers
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.bangers.length,
                        itemBuilder: (context, index) {
                          final data =
                              controller.bangers[index].data()
                                  as Map<String, dynamic>;

                          return GestureDetector(
                            onLongPress: () {
                              controller.showDeleteDialog(context, data['id']);
                            },
                            child: Music(
                              bangerId: data['id'],
                              onshareTap: () {
                                showAudioShareBottomSheet(
                                  img: data['imageUrl'],

                                  audioUrl: data['audioUrl'] ?? '',
                                  title: data['title'],
                                  description: data['description'],
                                  bangerId: data['id'],
                                );
                              },
                              onTap: () async {
                                final bangerData = await getBangerById(
                                  data['id'],
                                );
                                if (bangerData?['youtubeSong'] == true) {
                                  var link = bangerData?['audioUrl'] ?? '';
                                  if (bangerData?['isRawLink'] == true) {
                                    link = YoutubePlayer.convertUrlToId(link);
                                  }
                                  Get.to(
                                    () => YoutubePlayerScreen(
                                      videoUrl: link ?? '',
                                      bangerId: bangerData?['id'],
                                      ownerID: bangerData?['CreatedBy'] ?? '',
                                      currentUserId: AppConstants.userId,
                                      bangerImg: bangerData?['imageUrl'] ?? '',
                                      artistImageUrl: '',
                                      songImageUrl:
                                          bangerData?['imageUrl'] ?? '',
                                      artistName: '',
                                      songName: bangerData?['title'] ?? '',
                                      playlistName:
                                          bangerData?['playlistName'] ==
                                                  'Select'
                                              ? ''
                                              : bangerData?['playlistName'] ??
                                                  '',
                                      timeAgo: getTimeAgoFromTimestamp(
                                        bangerData?['createdAt'],
                                      ),
                                      comments:
                                          bangerData?['TotalComments'] ?? 0,
                                      shares: bangerData?['TotalShares'] ?? 0,
                                      playlistDropped:
                                          bangerData?['playlistName'] !=
                                          'Select',
                                      onCommentTap:
                                          () => Get.bottomSheet(
                                            CommentsBottomSheet(
                                              bangerImg:
                                                  bangerData?['imageUrl'] ?? '',
                                              ownerID:
                                                  bangerData?['CreatedBy'] ??
                                                  '',
                                              bangerId: bangerData?['id'],
                                              currentUserId:
                                                  AppConstants.userId,
                                              currentUserName:
                                                  AppConstants.userName,
                                            ),
                                            isScrollControlled: true,
                                          ),

                                      onShareTap: () {
                                        showAudioShareBottomSheet(
                                          img: data['imageUrl'],

                                          audioUrl:
                                              bangerData?['audioUrl'] ?? '',
                                          title: bangerData?['title'],
                                          description:
                                              bangerData?['description'],
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
                                          final List<Map<String, dynamic>>
                                          likes =
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
                                            userId:
                                                bangerData?['CreatedBy'] ?? '',
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                  return;
                                }
                                Get.to(
                                  () => SingleBangerPlayerView(
                                    bangers: controller.bangers,
                                    currentIndex: index,
                                  ),
                                );
                              },
                              title: data['title'] ?? 'No Title',
                              artist: data['artist'] ?? 'Unknown Artist',
                              imageUrl: data['imageUrl'] ?? '',
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40), // Bottom spacing
                    ],
                  ),
                ),
              );
            }),
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
