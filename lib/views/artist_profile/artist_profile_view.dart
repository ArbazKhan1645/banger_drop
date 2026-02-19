// views/artist_profile_view.dart
import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/Explore/widgets/comments_widget.dart';
import 'package:banger_drop/views/Explore/widgets/like_widget.dart';
import 'package:banger_drop/views/Explore/widgets/playlist_builder_widget.dart';
import 'package:banger_drop/views/VideoPlayer/youtube_player.dart';
import 'package:banger_drop/views/artist_profile/controller/artist_profile_controller.dart';
import 'package:banger_drop/views/Explore/widgets/share_widget.dart';

import 'package:banger_drop/views/playlist/playlist_view.dart';
import 'package:banger_drop/views/playlist/widgets/music_widget.dart';
import 'package:banger_drop/views/artist_profile/widgets/info_widget.dart';
import 'package:banger_drop/views/single_audio_player/single_player_view.dart';
import 'package:banger_drop/views/widgets/share_audio_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ArtistProfileView extends StatefulWidget {
  final String userId;

  const ArtistProfileView({super.key, required this.userId});

  @override
  State<ArtistProfileView> createState() => _ArtistProfileViewState();
}

class _ArtistProfileViewState extends State<ArtistProfileView> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

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
    final controller = Get.put(ArtistProfileController(widget.userId));
    controller.checkIfFollowing(widget.userId); // Pass the viewed user's ID
    controller.listenToFollowCounts(widget.userId);

    return Scaffold(
      backgroundColor: appColors.purple.withOpacity(.5),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.isBlockedByOther.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("User not Avialable", style: appThemes.small),
                TextButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: Text('Go Back'),
                ),
              ],
            ),
          );
        }
        final user = controller.userData.value;
        if (user == null) {
          return Center(child: Text("User not found", style: appThemes.small));
        }

        final bool isPrivate = controller.isPrivate.value;

        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/Picture1.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => ProfileInfoWidget(
                    uid: widget.userId,
                    imgUrl: user['img'] ?? '',
                    name: user['name'] ?? '---',
                    points: user['points'] ?? 0,
                    followers: controller.followersCount.value,
                    following: controller.followingCount.value,
                    isFollowing: controller.isFollowing.value,
                    hasRequested: controller.hasRequested.value,
                    onFollowToggle:
                        () => controller.sendFollowRequestToggle(widget.userId),
                    onFollowersTap:
                        () => controller.showFollowersDialog(widget.userId),
                    onFollowingTap:
                        () => controller.showFollowingDialog(widget.userId),
                    showFollowButton: uid != widget.userId || isPrivate,
                  ),
                ),
                Obx(() {
                  print("YouTube flag: ${controller.hasYouTubeLink.value}");
                  print("Spotify flag: ${controller.hasSpotifyLink.value}");
                  final hasYouTube = controller.hasYouTubeLink.value;
                  final hasSpotify = controller.hasSpotifyLink.value;

                  if (!hasYouTube && !hasSpotify) return SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (hasYouTube)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: IconButton(
                              icon: Image.asset(
                                'assets/images/youtube-svgrepo-com 1.png',
                                height: 28,
                              ),
                              onPressed: () async {
                                final url =
                                    controller.userData.value?['youtube'];
                                if (url != null && url.isNotEmpty) {
                                  final uri = Uri.parse(url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    print('Could not launch $url');
                                  }
                                }
                              },
                            ),
                          ),
                        if (hasSpotify)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),

                            child: IconButton(
                              icon: Image.asset(
                                'assets/images/spotify-color-svgrepo-com 1.png',
                                height: 28,
                              ),
                              onPressed: () async {
                                final url =
                                    controller.userData.value?['spotify'];
                                if (url != null && url.isNotEmpty) {
                                  final uri = Uri.parse(url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    print('Could not launch $url');
                                  }
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                }),

                if (isPrivate)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Center(
                      child: Text(
                        "Account is private",
                        style: appThemes.small.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else ...[
                  // Playlist section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      "Playlist",
                      style: appThemes.Large.copyWith(
                        fontSize: 23.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (controller.playlists.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      child: Center(
                        child: Text(
                          "No playlists available",
                          style: appThemes.small.copyWith(fontFamily: 'Sans'),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 190.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.playlists.length,
                        itemBuilder: (context, index) {
                          final doc = controller.playlists[index];
                          final data = doc.data() as Map<String, dynamic>;

                          return PlaylistBuilder(
                            playlistId: doc.id,
                            imageUrl: data['image'] ?? '',
                            playlistName: data['title'] ?? 'No Title',
                            artistName: data['authorName'] ?? 'Unknown Artist',
                            ontap:
                                () => Get.to(
                                  () => PlaylistView(playlistId: doc.id),
                                ),
                          );
                        },
                      ),
                    ),

                  // Bangers section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      "Bangers dropped",
                      style: appThemes.Large.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 23.sp,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: controller.bangers.length,
                      itemBuilder: (context, index) {
                        final data =
                            controller.bangers[index].data()
                                as Map<String, dynamic>;

                        return Music(
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
                            final bangerData = await getBangerById(data['id']);

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
                                          bangerImg:
                                              bangerData?['imageUrl'] ?? '',
                                          ownerID:
                                              bangerData?['CreatedBy'] ?? '',
                                          bangerId: bangerData?['id'],
                                          currentUserId: AppConstants.userId,
                                          currentUserName:
                                              AppConstants.userName,
                                        ),
                                        isScrollControlled: true,
                                      ),
                                  onShareTap: () {
                                    showAudioShareBottomSheet(
                                      img: data['imageUrl'],

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
                                bangers: controller.bangers,
                                currentIndex: index,
                              ),
                            );
                          },
                          title: data['title'] ?? 'No Title',
                          artist: data['artist'] ?? 'Unknown Artist',
                          imageUrl: data['imageUrl'] ?? '',
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
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
