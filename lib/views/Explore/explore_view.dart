import 'dart:math';
import 'package:banger_drop/notifications/notifications_services.dart';
import 'package:banger_drop/views/Explore/controllers/explore_controller.dart';
import 'package:banger_drop/views/Explore/widgets/ads_widget.dart';
import 'package:banger_drop/views/Explore/widgets/appbar_widget.dart';
import 'package:banger_drop/views/Explore/widgets/category_texts_widgets.dart';
import 'package:banger_drop/views/Explore/widgets/comments_widget.dart';
import 'package:banger_drop/views/Explore/widgets/like_widget.dart';
import 'package:banger_drop/views/Explore/widgets/playlist_builder_widget.dart';
import 'package:banger_drop/views/Explore/widgets/search_textfield.dart';
import 'package:banger_drop/views/Explore/widgets/share_widget.dart';
import 'package:banger_drop/views/Explore/widgets/songs_widget.dart';
import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/Notification/notification_view.dart';
import 'package:banger_drop/views/VideoPlayer/youtube_player.dart';
import 'package:banger_drop/views/artist_profile/artist_profile_view.dart';
import 'package:banger_drop/views/favourites/favourites_view.dart';
import 'package:banger_drop/views/music_player/music_player_view.dart';
import 'package:banger_drop/views/playlist/playlist_view.dart';
import 'package:banger_drop/views/spalsh/spalsh_screen.dart';
import 'package:banger_drop/views/widgets/share_audio_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class Explore extends StatefulWidget {
  const Explore({super.key});

  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> {
  final controller = Get.put(ExploreController());
  final auth = FirebaseAuth.instance.currentUser;
  int? adIndex;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      validateCurrentSession(user.uid);
    }
    AppConstants.initializeUserData();
    controller.selectedCategory.value = 'Recent'; // Default
    controller.handleCategorySelection(); // Load initial data
  }

  Future<void> validateCurrentSession(String uid) async {
    final fcmToken = await NotificationServices().getDeviceToken();

    if (fcmToken == null) {
      print('⚠️ Could not fetch FCM token.');
      return;
    }

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();

    if (data == null || data['devices'] == null) {
      _showForceLogoutDialog();
      return;
    }

    final List devices = data['devices'];
    final exists = devices.any((device) => device['token'] == fcmToken);

    if (!exists) {
      _showForceLogoutDialog();
    } else {
      print('✅ Valid device session, continue...');
    }
  }

  void _showForceLogoutDialog() {
    Get.defaultDialog(
      title: '',
      titlePadding: EdgeInsets.zero,
      barrierDismissible: false,
      contentPadding: const EdgeInsets.all(24),
      radius: 12,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 60),
          const SizedBox(height: 16),
          Text(
            'Session Expired',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'You have been logged out. Please log in again to continue.',
            style: TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
            ),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                Get.offAll(() => LogoAnimationScreen());
              } catch (e) {
                Get.snackbar(
                  "Error",
                  "Failed to logout. Please try again.",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.redAccent,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text(
              'Re-login',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/Picture1.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  await controller.fetchAllUsers();
                  await controller.handleCategorySelection();
                  setState(() => adIndex = null);
                },
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          WelcomeWidget(
                            onHeartTap: () => Get.to(() => FavouritesView()),
                            onNotificationTap:
                                () => Get.to(() => NotificationView()),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: SearchBarWidget(
                              onChanged: (value) {
                                controller.searchText.value = value.trim();
                                controller.filterPlaylists();
                                controller.filterBangers();
                              },
                            ),
                          ),

                          const SizedBox(height: 5),
                          CategorySelector(
                            categories: [
                              'Recent',
                              'Top 50',
                              'Today’s Hits',
                              'Discover',
                              'friends mix',
                            ],
                            onCategorySelected: (selectedCategory) {
                              controller.selectedCategory.value =
                                  selectedCategory;
                              controller.handleCategorySelection();
                              setState(() => adIndex = null); // reset ad
                            },
                          ),
                          const SizedBox(height: 10),

                          // Playlist Section
                          Obx(() {
                            if (controller.isLoadingCategory.value) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final playlists = controller.allPlaylists;
                            if (playlists.isEmpty) {
                              return Center(
                                child: Text(
                                  'No playlists found',
                                  style: appThemes.small,
                                ),
                              );
                            }

                            return SizedBox(
                              height: 200.h,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: playlists.length,
                                itemBuilder: (context, index) {
                                  final data =
                                      playlists[index].data()
                                          as Map<String, dynamic>;
                                  return PlaylistBuilder(
                                    playlistId: data['id'] ?? '',
                                    imageUrl: data['image'] ?? '',
                                    playlistName: data['title'] ?? 'No Title',
                                    artistName:
                                        controller.getUserNameByUid(
                                          data['created By'],
                                        ) ??
                                        'Unknown Artist',
                                    ontap: () async {
                                      await controller.viewPlaylist(
                                        data['id'],
                                        auth!.uid,
                                      );
                                      Get.to(
                                        () => PlaylistView(
                                          playlistId: data['id'],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          }),

                          Padding(
                            padding: const EdgeInsets.only(left: 5.0, top: 20),
                            child: Text(
                              "Feed",
                              style: appThemes.Large.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Feed Section
                    SliverToBoxAdapter(
                      child: Obx(() {
                        if (controller.isLoadingCategory.value) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final bangers = controller.bangers;
                        if (bangers.isEmpty) {
                          return Center(
                            child: Text(
                              'No bangers found.',
                              style: appThemes.Medium,
                            ),
                          );
                        }

                        final insertAd = bangers.length >= 4;
                        adIndex ??=
                            insertAd ? Random().nextInt(bangers.length) : -1;

                        return ListView.builder(
                          itemCount:
                              insertAd ? bangers.length + 1 : bangers.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            // Insert ad widget
                            if (insertAd && index == adIndex) {
                              return AdsWidget(
                                ads: [
                                  AdItem(
                                    imageUrl:
                                        'https://neilpatel.com/wp-content/uploads/2017/08/ads-700x420.jpg',
                                    onTap: () => print('Ad 1 tapped'),
                                  ),
                                  AdItem(
                                    imageUrl:
                                        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTZBRvZsXEf02-Ao0PlrNzak3GhFfS9yrq4AA&s',
                                    onTap: () => print('Ad 2 tapped'),
                                  ),
                                  AdItem(
                                    imageUrl:
                                        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTR4ATSA2e1kCcfPjw2n9hCvV_xvpqBTb8ZGA&s',
                                    onTap: () => print('Ad 3 tapped'),
                                  ),
                                ],
                              );
                            }

                            final adjustedIndex =
                                insertAd && index > adIndex!
                                    ? index - 1
                                    : index;

                            // Safety check to avoid range error
                            if (adjustedIndex >= bangers.length)
                              return const SizedBox.shrink();

                            final data =
                                bangers[adjustedIndex].data()
                                    as Map<String, dynamic>;

                            return SocialPostWidget(
                              ProfileTap: () {
                                Get.to(
                                  () => ArtistProfileView(
                                    userId: data['CreatedBy'] ?? '',
                                  ),
                                );
                              },
                              bangerImg: data['imageUrl'] ?? '',
                              ownerID: data['CreatedBy'] ?? '',
                              description: data['description'] ?? '',
                              bangerId: data['id'],
                              currentUserId: AppConstants.userId,
                              playlistDropped: data['isbanger'] != true,
                              artistImageUrl:
                                  controller.getUserImgByUid(
                                    data['CreatedBy'] ?? '',
                                  ) ??
                                  '',
                              songImageUrl: data['imageUrl'] ?? '',
                              artistName:
                                  controller.getUserNameByUid(
                                    data['CreatedBy'] ?? '',
                                  ) ??
                                  '',
                              songName:
                                  '${data['title'] ?? ''} ${data['Repost'] == true ? '- Reposted from ${controller.getUserNameByUid(data['Owner'] ?? '') ?? ''}' : ''}',
                              playlistName:
                                  data['playlistName'] == 'Select'
                                      ? ''
                                      : data['playlistName'] ?? '',
                              timeAgo: controller.getTimeAgoFromTimestamp(
                                data['createdAt'],
                              ),
                              comments: data['TotalComments'] ?? 0,
                              shares: data['TotalShares'] ?? 0,
                              onTap: () async {
                                controller.incrementPlaysOncePerUser(
                                  data['id'],
                                  auth!.uid,
                                );
                                if (data['youtubeSong'] == true) {
                                  var link = data['audioUrl'] ?? '';
                                  if (data['isRawLink'] == true) {
                                    link = YoutubePlayer.convertUrlToId(link);
                                  }
                                  Get.to(
                                    () => YoutubePlayerScreen(
                                      videoUrl: link ?? '',
                                      bangerId: data['id'],
                                      ownerID: data['CreatedBy'] ?? '',
                                      currentUserId: AppConstants.userId,
                                      bangerImg: data['imageUrl'] ?? '',
                                      artistImageUrl:
                                          controller.getUserImgByUid(
                                            data['CreatedBy'] ?? '',
                                          ) ??
                                          '',
                                      songImageUrl: data['imageUrl'] ?? '',
                                      artistName:
                                          controller.getUserNameByUid(
                                            data['CreatedBy'] ?? '',
                                          ) ??
                                          '',
                                      songName: data['title'] ?? '',
                                      playlistName:
                                          data['playlistName'] == 'Select'
                                              ? ''
                                              : data['playlistName'] ?? '',
                                      timeAgo: controller
                                          .getTimeAgoFromTimestamp(
                                            data['createdAt'],
                                          ),
                                      comments: data['TotalComments'] ?? 0,
                                      shares: data['TotalShares'] ?? 0,
                                      playlistDropped:
                                          data['playlistName'] != 'Select',
                                      onCommentTap:
                                          () => Get.bottomSheet(
                                            CommentsBottomSheet(
                                              bangerImg: data['imageUrl'] ?? '',
                                              ownerID: data['CreatedBy'] ?? '',
                                              bangerId: data['id'],
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

                                          audioUrl: data['audioUrl'] ?? '',
                                          title: data['title'],
                                          description: data['description'],
                                          bangerId: data['id'],
                                        );
                                      },
                                      onLikeInfoTap: () async {
                                        final doc =
                                            await FirebaseFirestore.instance
                                                .collection('Bangers')
                                                .doc(data['id'])
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
                                            bangerId: data['id'],
                                          ),
                                          isScrollControlled: true,
                                        );
                                      },
                                      ProfileTap: () {
                                        Get.to(
                                          () => ArtistProfileView(
                                            userId: data['CreatedBy'] ?? '',
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => MusicPlayerView(
                                          id: data['id'].toString(),
                                          songs: bangers,
                                          currentIndex: adjustedIndex,
                                        ),
                                  ),
                                );
                              },
                              onCommentTap:
                                  () => Get.bottomSheet(
                                    CommentsBottomSheet(
                                      bangerImg: data['imageUrl'] ?? '',
                                      ownerID: data['CreatedBy'] ?? '',
                                      bangerId: data['id'],
                                      currentUserId: AppConstants.userId,
                                      currentUserName: AppConstants.userName,
                                    ),
                                    isScrollControlled: true,
                                  ),
                              onShareTap: () {
                                showAudioShareBottomSheet(
                                  img: data['imageUrl'],

                                  audioUrl: data['audioUrl'] ?? '',
                                  title: data['title'],
                                  description: data['description'],
                                  bangerId: data['id'],
                                );
                              },
                              onLikeInfoTap: () async {
                                final doc =
                                    await FirebaseFirestore.instance
                                        .collection('Bangers')
                                        .doc(data['id'])
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
                                  SharesBottomSheet(bangerId: data['id']),
                                  isScrollControlled: true,
                                );
                              },
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
