import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/Explore/widgets/comments_widget.dart';
import 'package:banger_drop/views/Explore/widgets/like_widget.dart';
import 'package:banger_drop/views/Explore/widgets/playlist_builder_widget.dart';
import 'package:banger_drop/views/VideoPlayer/youtube_player.dart';
import 'package:banger_drop/views/artist_profile/artist_profile_view.dart';
import 'package:banger_drop/views/favourites/controller/fav_controller.dart';
import 'package:banger_drop/views/music_player/music_player_view.dart';
import 'package:banger_drop/views/playlist/playlist_view.dart';
import 'package:banger_drop/views/playlist/widgets/music_widget.dart';
import 'package:banger_drop/views/single_audio_player/single_player_view.dart';
import 'package:banger_drop/views/widgets/share_audio_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../Explore/widgets/share_widget.dart' show SharesBottomSheet;

class FavouritesView extends StatefulWidget {
  const FavouritesView({super.key});

  @override
  State<FavouritesView> createState() => _FavouritesViewState();
}

class _FavouritesViewState extends State<FavouritesView> {
  final controller = Get.put(FavouritesController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(backgroundColor: Colors.transparent),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    'assets/images/Picture1.png',
                  ), // Replace with your image path
                  fit: BoxFit.cover,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 50),
                    IconButton(
                      onPressed: () {
                        Get.back();
                      },
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        // size: 30,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Favorites ",
                            style: appThemes.Large.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 22.sp,
                            ),
                          ),
                          Text(
                            "",
                            style: appThemes.Medium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: appColors.textGrey.withOpacity(.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "Playlists ",
                        style: appThemes.Large.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Obx(() {
                      if (controller.favoriteDocs.isEmpty ||
                          controller.favoriteDocs == []) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'No favourite playlist found',
                              style: appThemes.small,
                            ),
                          ],
                        );
                      }
                      return SizedBox(
                        height: 200.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: controller.favoriteDocs.length,
                          itemBuilder: (context, index) {
                            final data =
                                controller.favoriteDocs[index].data()
                                    as Map<String, dynamic>;
                            return PlaylistBuilder(
                              playlistId: data['id'] ?? '',
                              imageUrl: data['image'] ?? '',
                              playlistName: data['title'] ?? 'No Title',
                              artistName:
                                  data['authorName'] ?? 'Unknown Artist',
                              ontap:
                                  () => Get.to(
                                    () => PlaylistView(
                                      playlistId: data['id'] ?? '',
                                    ),
                                  ),
                            );
                          },
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "Bangers",
                        style: appThemes.Large.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.sp,
                        ),
                      ),
                    ),
                    Obx(() {
                      if (controller.favTrackDocs.isEmpty ||
                          controller.favTrackDocs == []) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'No favourite playlist found',
                              style: appThemes.small,
                            ),
                          ],
                        );
                      }
                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: controller.favTrackDocs.length,
                        // so it's not hidden under image
                        itemBuilder: (context, index) {
                          return Music(
                            bangerId: controller.favTrackDocs[index]['id'],
                            onshareTap: () {
                              showAudioShareBottomSheet(
                                img: controller.favTrackDocs[index]['imageUrl'],
                                audioUrl:
                                    controller
                                        .favTrackDocs[index]['audioUrl'] ??
                                    '',
                                title:
                                    controller.favTrackDocs[index]['title']
                                        .toString(),
                                description:
                                    controller
                                        .favTrackDocs[index]['description']
                                        .toString(),
                                bangerId:
                                    controller.favTrackDocs[index]['id']
                                        .toString(), // ✅ example id
                              );
                            },
                            onTap: () async {
                              final bangerData = await controller.getBangerById(
                                controller.favTrackDocs[index]['id'],
                              );
                              print(bangerData?['id']);
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
                                        img: bangerData?['imageUrl'],

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
                                  bangers: controller.favTrackDocs,
                                  currentIndex: index,
                                ),
                              );
                            },
                            title:
                                controller.favTrackDocs[index]['title']
                                    .toString(),
                            artist:
                                controller.favTrackDocs[index]['artist']
                                    .toString(),
                            imageUrl:
                                controller.favTrackDocs[index]['imageUrl']
                                    .toString(),
                          );
                        },
                      );
                    }),
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
