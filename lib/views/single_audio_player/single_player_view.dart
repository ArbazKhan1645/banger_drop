import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/Explore/widgets/comments_widget.dart';
import 'package:banger_drop/views/Explore/widgets/like_widget.dart';
import 'package:banger_drop/views/Explore/widgets/share_widget.dart';
import 'package:banger_drop/views/playlist/widgets/playlis_appbar_widget.dart';
import 'package:banger_drop/views/single_audio_player/controller/single_audio_controller.dart';
import 'package:banger_drop/views/widgets/loading_widget.dart';
import 'package:banger_drop/views/widgets/share_audio_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SingleBangerPlayerView extends StatelessWidget {
  final List<dynamic> bangers;
  final int currentIndex;

  SingleBangerPlayerView({
    super.key,
    required this.bangers,
    required this.currentIndex,
  });

  final controller = Get.find<SingleBangerPlayerController>();

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  String _timeAgoSince(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }

  Widget _buildSocialBar(Map<String, dynamic> data) {
    final totalLikes = data['TotalLikes'] ?? 0;
    final totalShares = data['TotalShares'] ?? 0;
    final List likes = data['Likes'] ?? [];
    final isLiked = likes.any((e) => e['id'] == AppConstants.userId);
    final bangerId = data['id'];
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return Column(
      children: [
        Row(
          children: [
            if (createdAt != null)
              Text(
                _timeAgoSince(createdAt),
                style: const TextStyle(color: Colors.pinkAccent),
              ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Get.bottomSheet(
                  LikesBottomSheet(
                    likeMaps: List<Map<String, dynamic>>.from(likes),
                  ),
                  isScrollControlled: true,
                );
              },
              child: Text(
                '$totalLikes likes',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                Get.bottomSheet(
                  SharesBottomSheet(bangerId: bangerId),
                  isScrollControlled: true,
                );
              },
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
              onPressed: () => _handleLike(data),
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.white,
              ),
            ),
            IconButton(
              onPressed: () {
                Get.bottomSheet(
                  CommentsBottomSheet(
                    bangerImg: data['imageUrl'] ?? '',
                    ownerID: data['CreatedBy'] ?? '',
                    bangerId: bangerId,
                    currentUserId: AppConstants.userId,
                    currentUserName: AppConstants.userName,
                  ),
                  isScrollControlled: true,
                );
              },
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            ),
            IconButton(
              onPressed: () {
                showAudioShareBottomSheet(
                  img: data['imageUrl'],

                  audioUrl: data['audioUrl'] ?? '',
                  title: data['title'] ?? '',
                  description: data['description'] ?? '',
                  bangerId: bangerId,
                );
              },
              icon: const Icon(Icons.share_outlined, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleLike(Map<String, dynamic> data) async {
    final docRef = FirebaseFirestore.instance
        .collection('Bangers')
        .doc(data['id']);
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
        'img': AppConstants.userImg,
        'time': DateTime.now().toIso8601String(),
      });
      totalLikes += 1;

      if (AppConstants.userId != data['CreatedBy']) {
        await FirebaseFirestore.instance.collection('notifications').add({
          "bangerId": data['id'],
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

    await docRef.update({'Likes': likes, 'TotalLikes': totalLikes});
  }

  @override
  Widget build(BuildContext context) {
    Future.microtask(() {
      if (controller.bangers.isEmpty ||
          controller.currentIndex.value != currentIndex) {
        controller.loadBangerList(bangers, currentIndex);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (controller.error.isNotEmpty) {
          return Center(
            child: Text(
              controller.error.value,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final song = controller.currentSong;
        final title = song['title'] ?? '';
        final artist = song['artist'] ?? '';
        final image = song['imageUrl'] ?? '';
        final id = song['id'] ?? '';
        final pos = controller.position.value;
        final dur = controller.duration.value;

        final posFraction =
            dur.inMilliseconds == 0
                ? 0.0
                : pos.inMilliseconds / dur.inMilliseconds;

        return Stack(
          children: [
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => LoadingWidget(color: Colors.black),
                errorWidget:
                    (context, url, error) => const Icon(Icons.broken_image),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 60),
                BangerAppbarWidget(
                  id: id,
                  onBackPressed: () => Get.back(),
                  onSharePressed: () {}, // No need as share is in social bar
                ),
                const Spacer(),
                Container(
                  height: ScreenUtil().screenHeight * .65,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black,
                        Colors.black.withOpacity(.6),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Obx(() {
                    final isLoading = controller.isLoading.value;
                    final isPlaying = controller.isPlaying.value;
                    final isNextDisabled = controller.isNextDisabled.value;
                    final repeatOne = controller.repeatOne.value;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(title, style: appThemes.Large),
                        const SizedBox(height: 8),
                        Text(artist, style: appThemes.Medium),
                        const SizedBox(height: 20),
                        Slider(
                          value: posFraction.clamp(0.0, 1.0),
                          onChanged: isLoading ? null : controller.seekTo,
                          activeColor: Colors.pink,
                          inactiveColor: Colors.white30,
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
                              icon: Icon(
                                Icons.skip_previous,
                                size: 36,
                                color:
                                    isLoading ? Colors.white30 : Colors.white,
                              ),
                              onPressed:
                                  isLoading ? null : controller.playPrevious,
                            ),
                            IconButton(
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_circle
                                    : Icons.play_circle,
                                size: 70,
                                color:
                                    isLoading ? Colors.white30 : Colors.white,
                              ),
                              onPressed:
                                  isLoading ? null : controller.togglePlayPause,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.skip_next,
                                size: 36,
                                color:
                                    isLoading || isNextDisabled
                                        ? Colors.white30
                                        : Colors.white,
                              ),
                              onPressed:
                                  isLoading || isNextDisabled
                                      ? null
                                      : controller.playNext,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                              onPressed: controller.toggleRepeat,
                              icon: Icon(
                                Icons.repeat_one,
                                color:
                                    repeatOne ? Colors.white : Colors.white54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (song['id'] != null &&
                            (song['id'] as String).isNotEmpty)
                          StreamBuilder<DocumentSnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('Bangers')
                                    .doc(song['id'])
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData)
                                return const SizedBox.shrink();
                              final data =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              return _buildSocialBar(data);
                            },
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}
