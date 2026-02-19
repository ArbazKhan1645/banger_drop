import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/Explore/widgets/comments_widget.dart';
import 'package:banger_drop/views/Explore/widgets/like_widget.dart';
import 'package:banger_drop/views/VideoPlayer/youtube_player.dart';
import 'package:banger_drop/views/artist_profile/artist_profile_view.dart';
import 'package:banger_drop/views/widgets/loading_widget.dart';
import 'package:banger_drop/views/widgets/share_audio_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../Explore/widgets/share_widget.dart';

class StoryViewer extends StatefulWidget {
  final String type;
  final String url;
  final String userImage;
  final String userName;

  const StoryViewer({
    super.key,
    required this.type,
    required this.url,
    required this.userImage,
    required this.userName,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  late final AudioPlayer _audioPlayer;
  bool showYTButton = false;
  Map<String, dynamic>? bangerData;

  bool isAudioLoading = true;
  bool isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.playerStateStream.listen((state) {
      if (state.playing && state.processingState == ProcessingState.ready) {
        setState(() {
          isAudioPlaying = true;
          isAudioLoading = false;
        });
        print('▶️ Audio is now playing');
      } else if (state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering) {
        setState(() => isAudioLoading = true);
      } else if (state.processingState == ProcessingState.completed) {
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
      }
    });

    if (widget.type == 'audio') {
      _fetchBanger();
    }
  }

  Future<void> _fetchBanger() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('Bangers')
              .where('audioUrl', isEqualTo: widget.url)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        bangerData = snapshot.docs.first.data();
        bangerData?['id'] = snapshot.docs.first.id;

        if (bangerData?['youtubeSong'] == true) {
          setState(() {
            showYTButton = true;
            isAudioLoading = false; // ✅ Fix: show UI immediately
          });
        } else {
          await _playAudio(widget.url);
        }
      } else {
        print('No banger matched. Playing fallback audio');
        await _playAudio(widget.url);
      }
    } catch (e) {
      print('❌ Error fetching banger: $e');
      setState(() => isAudioLoading = false);
    }
  }

  void _openYouTubePlayer() {
    String link = bangerData?['audioUrl'] ?? '';
    if (bangerData?['isRawLink'] == true) {
      link = YoutubePlayer.convertUrlToId(link) ?? '';
    }

    Get.to(
      () => YoutubePlayerScreen(
        videoUrl: link,
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
        timeAgo: getTimeAgoFromTimestamp(bangerData?['createdAt']),
        comments: bangerData?['TotalComments'] ?? 0,
        shares: bangerData?['TotalShares'] ?? 0,
        playlistDropped: bangerData?['playlistName'] != 'Select',
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
                List<Map<String, dynamic>>.from(data['Likes'] ?? []);
            Get.bottomSheet(
              LikesBottomSheet(likeMaps: likes),
              isScrollControlled: true,
            );
          }
        },
        onshareInfoTap: () {
          Get.bottomSheet(
            SharesBottomSheet(bangerId: bangerData?['id']),
            isScrollControlled: true,
          );
        },
        ProfileTap: () {
          Get.to(
            () => ArtistProfileView(userId: bangerData?['CreatedBy'] ?? ''),
          );
        },
      ),
    );
  }

  Future<void> _playAudio(String url) async {
    try {
      setState(() {
        isAudioLoading = true;
        isAudioPlaying = false;
      });

      await _audioPlayer.setUrl(url);
      print('🎵 Audio URL set');
      await _audioPlayer.play();
    } catch (e) {
      print('❌ Error playing audio: $e');
      setState(() => isAudioLoading = false);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque, // ✅ Ensures tap is detected anywhere

        onTap: () {
          _audioPlayer.stop();
          Navigator.of(context).pop();
        },
        child: Stack(
          children: [
            Center(
              child:
                  widget.type == 'audio'
                      ? isAudioLoading
                          ? const LoadingWidget(color: Colors.white)
                          : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.music_note_rounded,
                                size: 80,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Now Playing...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              if (showYTButton) ...[
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _openYouTubePlayer,
                                  icon: const Icon(Icons.play_circle),
                                  label: const Text('Watch on YouTube'),
                                ),
                              ],
                            ],
                          )
                      : CachedNetworkImage(
                        imageUrl: widget.url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder:
                            (context, url) => const Center(
                              child: LoadingWidget(color: Colors.white),
                            ),
                        errorWidget:
                            (context, url, error) =>
                                const Icon(Icons.error, color: Colors.red),
                      ),
            ),

            // Top user bar
            Positioned(
              top: 50.h,
              left: 16.w,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(widget.userImage),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
