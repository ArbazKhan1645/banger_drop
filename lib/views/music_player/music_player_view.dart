import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/helper/shared_prefrences_helper.dart';
import 'package:banger_drop/views/music_player/controller/player_controller.dart';
import 'package:banger_drop/views/widgets/loading_widget.dart';
import 'package:banger_drop/views/widgets/share_audio_widget.dart';
import 'package:banger_drop/views/playlist/widgets/playlis_appbar_widget.dart';
import 'package:banger_drop/views/Explore/widgets/comments_widget.dart';
import 'package:banger_drop/views/Explore/widgets/like_widget.dart';
import 'package:banger_drop/views/Explore/widgets/share_widget.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
// imports remain unchanged

class MusicPlayerView extends StatefulWidget {
  final List<DocumentSnapshot> songs;
  final int currentIndex;
  final id;

  const MusicPlayerView({
    super.key,
    required this.songs,
    required this.currentIndex,
    required this.id,
  });

  @override
  State<MusicPlayerView> createState() => _MusicPlayerViewState();
}

class _MusicPlayerViewState extends State<MusicPlayerView> {
  late final AudioPlayerController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AudioPlayerController>()) {
      Get.delete<AudioPlayerController>();
    }
    controller = Get.put(AudioPlayerController());
    controller.loadPlaylist(widget.songs, widget.currentIndex);
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  Future<void> _handleLike(Map<String, dynamic> data, String bangerId) async {
    final ref = FirebaseFirestore.instance.collection('Bangers').doc(bangerId);
    List<Map<String, dynamic>> likes = List<Map<String, dynamic>>.from(
      data['Likes'] ?? [],
    );
    int totalLikes = data['TotalLikes'] ?? 0;

    final alreadyLiked = likes.any((like) => like['id'] == AppConstants.userId);

    if (alreadyLiked) {
      likes.removeWhere((like) => like['id'] == AppConstants.userId);
      totalLikes = totalLikes > 0 ? totalLikes - 1 : 0;
    } else {
      likes.add({
        'id': AppConstants.userId,
        'name': AppConstants.userName,
        'time': DateTime.now().toIso8601String(),
        'img': AppConstants.userImg,
      });
      totalLikes += 1;

      if (AppConstants.userId != data['CreatedBy']) {
        await FirebaseFirestore.instance.collection('notifications').add({
          "bangerId": bangerId,
          "bangerOwnerId": data['CreatedBy'],
          "type": 'like',
          "users": [
            {
              "uid": AppConstants.userId,
              "name": AppConstants.userName,
              "img": AppConstants.userImg,
            },
          ],
          "bangerImg": data['imageUrl'],
          "timestamp": Timestamp.now(),
          "seenBy": [],
        });
      }
    }

    await ref.update({'Likes': likes, 'TotalLikes': totalLikes});
  }

  String timeAgoSinceDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }

  Widget _buildSocialBar(Map<String, dynamic> data, String bangerId) {
    int totalLikes = data['TotalLikes'] ?? 0;
    int totalShares = data['TotalShares'] ?? 0;
    final List<Map<String, dynamic>> likes = List<Map<String, dynamic>>.from(
      data['Likes'] ?? [],
    );
    final isLiked = likes.any((like) => like['id'] == AppConstants.userId);

    return Column(
      children: [
        Row(
          children: [
            Text(
              timeAgoSinceDate(data['createdAt']?.toDate() ?? DateTime.now()),
              style: const TextStyle(color: Colors.pinkAccent),
            ),
            const Spacer(),
            GestureDetector(
              onTap:
                  () => Get.bottomSheet(
                    LikesBottomSheet(likeMaps: likes),
                    isScrollControlled: true,
                  ),
              child: Text(
                '$totalLikes likes',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap:
                  () => Get.bottomSheet(
                    SharesBottomSheet(bangerId: bangerId),
                    isScrollControlled: true,
                  ),
              child: Text(
                '$totalShares shares',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () => _handleLike(data, bangerId),
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.white,
              ),
            ),
            IconButton(
              onPressed:
                  () => Get.bottomSheet(
                    CommentsBottomSheet(
                      bangerImg: data['imageUrl'] ?? '',
                      ownerID: data['CreatedBy'] ?? '',
                      bangerId: bangerId,
                      currentUserId: AppConstants.userId,
                      currentUserName: AppConstants.userName,
                    ),
                    isScrollControlled: true,
                  ),
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            ),
            IconButton(
              onPressed:
                  () => showAudioShareBottomSheet(
                    img: data['imageUrl'],

                    audioUrl: data['audioUrl'] ?? '',
                    title: data['title'],
                    description: data['description'],
                    bangerId: bangerId,
                  ),
              icon: const Icon(Icons.share_outlined, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColors.white,
      body: Obx(() {
        if (controller.error.isNotEmpty && !controller.isPlaying.value) {
          return Center(
            child: Text(
              controller.error.value,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          );
        }

        final current = controller.currentSong;
        final title = current['title'] ?? '';
        final artist = current['artist'] ?? '';
        final image = current['imageUrl'] ?? '';
        final desc = current['description'] ?? '';
        final audioUrl = current['audioUrl'] ?? '';
        final bangerId = current['id'] ?? '';
        final pos = controller.position.value;
        final dur = controller.duration.value;

        return Stack(
          children: [
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: image,
                placeholder:
                    (context, url) => LoadingWidget(color: Colors.black),
                errorWidget: (context, url, error) => const Icon(Icons.error),
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(color: appColors.black.withOpacity(.2)),
            ),
            Column(
              children: [
                const SizedBox(height: 60),
                BangerAppbarWidget(
                  id: bangerId,
                  onBackPressed: () => Get.back(),
                  onSharePressed:
                      () => showAudioShareBottomSheet(
                        img: image,
                        audioUrl: audioUrl,
                        title: title,
                        description: desc,
                        bangerId: bangerId,
                      ),
                ),
                const Spacer(),
                Container(
                  height: ScreenUtil().screenHeight * .7,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        appColors.black,
                        appColors.black.withOpacity(.5),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('Bangers')
                            .doc(bangerId)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(title, style: appThemes.Large),
                          const SizedBox(height: 8),
                          Text(artist, style: appThemes.Medium),
                          const SizedBox(height: 20),
                          Slider(
                            value:
                                dur.inMilliseconds == 0
                                    ? 0.0
                                    : pos.inMilliseconds / dur.inMilliseconds,
                            onChanged:
                                controller.isReady.value
                                    ? (v) => controller.seekTo(v)
                                    : null,
                            activeColor: appColors.pink,
                            inactiveColor: appColors.black.withOpacity(.5),
                            thumbColor: appColors.white,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(pos),
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                _formatDuration(dur),
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed:
                                    controller.isReady.value
                                        ? controller.playPreviousSong
                                        : null,
                                icon: Icon(
                                  Icons.skip_previous,
                                  size: 36,
                                  color:
                                      controller.isReady.value
                                          ? Colors.white
                                          : Colors.white30,
                                ),
                              ),
                              IconButton(
                                onPressed:
                                    controller.isReady.value
                                        ? controller.togglePlayPause
                                        : null,
                                icon: Icon(
                                  controller.isPlaying.value
                                      ? Icons.pause_circle
                                      : Icons.play_circle,
                                  size: 70,
                                  color:
                                      controller.isReady.value
                                          ? Colors.white
                                          : Colors.white30,
                                ),
                              ),
                              IconButton(
                                onPressed:
                                    controller.isReady.value
                                        ? controller.playNextSong
                                        : null,
                                icon: Icon(
                                  Icons.skip_next,
                                  size: 36,
                                  color:
                                      controller.isReady.value
                                          ? Colors.white
                                          : Colors.white30,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: controller.toggleRepeat,
                                icon: Icon(
                                  Icons.repeat_one,
                                  color:
                                      controller.repeatOne.value
                                          ? Colors.white
                                          : Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildSocialBar(data, bangerId),
                          SizedBox(height: 80.h),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}
