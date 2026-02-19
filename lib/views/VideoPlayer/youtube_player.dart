import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/Explore/widgets/comments_widget.dart';
import 'package:banger_drop/views/Explore/widgets/like_widget.dart';
import 'package:banger_drop/views/VideoPlayer/widgets/social_widgets.dart';
import 'package:banger_drop/views/widgets/share_audio_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../Explore/widgets/share_widget.dart' show SharesBottomSheet;

class YoutubePlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String bangerId;
  final String ownerID;
  final String currentUserId;
  final String? bangerImg;

  final String artistImageUrl;
  final String songImageUrl;
  final String artistName;
  final String songName;
  final String? playlistName;
  final String timeAgo;
  final int comments;
  final int shares;
  final bool playlistDropped;

  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;
  final VoidCallback onLikeInfoTap;
  final VoidCallback onshareInfoTap;
  final VoidCallback ProfileTap;

  // 🔧 Added
  final isPlaylist;
  final playlistId;

  const YoutubePlayerScreen({
    super.key,
    required this.videoUrl,
    required this.bangerId,
    required this.ownerID,
    required this.currentUserId,
    required this.bangerImg,
    required this.artistImageUrl,
    required this.songImageUrl,
    required this.artistName,
    required this.songName,
    this.playlistName,
    required this.timeAgo,
    required this.comments,
    required this.shares,
    required this.playlistDropped,
    required this.onCommentTap,
    required this.onShareTap,
    required this.onLikeInfoTap,
    required this.onshareInfoTap,
    required this.ProfileTap,
    this.isPlaylist = false,
    this.playlistId,
  });

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  late YoutubePlayerController _controller;
  List<DocumentSnapshot> bangerDocs = [];
  int currentIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBangers();
    // print(
    //   "================================================${widget.playlistId}",
    // );
  }

  Future<void> fetchBangers() async {
    setState(() => isLoading = true);
    final firestore = FirebaseFirestore.instance;

    if (widget.isPlaylist && widget.playlistId != null) {
      print('=============================isplaylist');
      final playlistDoc =
          await firestore.collection('Playlist').doc(widget.playlistId).get();

      if (playlistDoc.exists) {
        final data = playlistDoc.data() as Map<String, dynamic>;
        final List<dynamic> bangerRefs = data['bangers'] ?? [];

        List<String> bangerIds =
            bangerRefs
                .map((entry) => entry['id']?.toString())
                .where((id) => id != null)
                .cast<String>()
                .toList();

        final fetchedDocs = await Future.wait(
          bangerIds.map((id) => firestore.collection('Bangers').doc(id).get()),
        );

        bangerDocs =
            fetchedDocs.where((doc) {
              final docData = doc.data() as Map<String, dynamic>?;
              return docData != null && docData['youtubeSong'] == true;
            }).toList();

        final index = bangerDocs.indexWhere((doc) => doc.id == widget.bangerId);
        currentIndex = index != -1 ? index : 0;

        if (bangerDocs.isNotEmpty) {
          initializePlayer(getCurrentVideoUrl());
        } else {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No valid YouTube songs found in the playlist."),
            ),
          );
        }

        return; // ✅ DO NOT FALLBACK after this
      }
    }

    // 🔁 Only if not a playlist or playlist ID is invalid
    if (!widget.isPlaylist) {
      print(
        '=============================${widget.playlistId} and ${widget.isPlaylist}',
      );
      final snapshot =
          await firestore
              .collection('Bangers')
              .where('youtubeSong', isEqualTo: true)
              .orderBy('createdAt', descending: false)
              .get();

      bangerDocs = snapshot.docs;

      final index = bangerDocs.indexWhere((doc) => doc.id == widget.bangerId);
      currentIndex = index != -1 ? index : 0;

      initializePlayer(getCurrentVideoUrl());
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No valid playlist found.")));
    }
  }

  String getCurrentVideoUrl() {
    if (bangerDocs.isEmpty) return '';
    final url =
        bangerDocs[currentIndex]['audioUrl']; // Change to youtubeUrl if needed
    return url is String ? url : '';
  }

  void initializePlayer(String videoUrl) {
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    )..addListener(() {
      if (_controller.value.playerState == PlayerState.ended) {
        // Delay to allow UI update or prevent double-calls
        Future.delayed(const Duration(milliseconds: 300), () {
          widget.isPlaylist ? playNext() : playPrevious();
        });
      }
    });

    setState(() {
      isLoading = false;
    });
  }

  void playNext() {
    setState(() {
      if (currentIndex < bangerDocs.length - 1) {
        currentIndex++;
      } else {
        currentIndex = 0; // 👈 restart from beginning
      }
      isLoading = true;
    });

    _controller.load(YoutubePlayer.convertUrlToId(getCurrentVideoUrl()) ?? '');

    setState(() => isLoading = false);
  }

  void playPrevious() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        isLoading = true;
      });
      _controller.load(
        YoutubePlayer.convertUrlToId(getCurrentVideoUrl()) ?? '',
      );
      setState(() => isLoading = false);
    }
  }

  DocumentSnapshot get currentBanger => bangerDocs[currentIndex];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String decodeHtmlEntities(String input) {
    final unescape = HtmlUnescape();
    return unescape.convert(input);
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()),
        )
        : YoutubePlayerBuilder(
          player: YoutubePlayer(controller: _controller),
          builder: (context, player) {
            final data = currentBanger.data() as Map<String, dynamic>;

            return Scaffold(
              backgroundColor: appColors.purple,
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
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          const SizedBox(height: 50),
                          player,
                          SafeArea(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          decodeHtmlEntities(data['title'] ?? ''),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),

                      // Action Bar
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: BangerActionsBar(
                          key: ValueKey(
                            currentBanger.id,
                          ), // 👈 this helps trigger rebuild
                          bangerId: currentBanger.id,
                          ownerID: data['CreatedBy'] ?? '',
                          currentUserId: widget.currentUserId,
                          bangerImg: data['imageUrl'] ?? '',
                          timeAgo: widget.timeAgo,
                          shares: data['TotalShares'] ?? 0,
                          onCommentTap:
                              () => Get.bottomSheet(
                                CommentsBottomSheet(
                                  bangerImg: data['imageUrl'] ?? '',
                                  ownerID: data['CreatedBy'] ?? '',
                                  bangerId: currentBanger.id,
                                  currentUserId: widget.currentUserId,
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
                              bangerId: currentBanger.id,
                            );
                          },
                          onLikeInfoTap: () async {
                            final doc =
                                await FirebaseFirestore.instance
                                    .collection('Bangers')
                                    .doc(currentBanger.id)
                                    .get();
                            if (doc.exists) {
                              final likes = List<Map<String, dynamic>>.from(
                                doc.data()?['Likes'] ?? [],
                              );
                              Get.bottomSheet(
                                LikesBottomSheet(likeMaps: likes),
                                isScrollControlled: true,
                              );
                            }
                          },
                          onshareInfoTap: () {
                            Get.bottomSheet(
                              SharesBottomSheet(bangerId: currentBanger.id),
                              isScrollControlled: true,
                            );
                          },
                        ),
                      ),

                      // Navigation Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed:
                                  widget.isPlaylist ? playPrevious : playNext,
                              icon: const Icon(Icons.skip_previous),
                              label: const Text("Previous"),
                            ),
                            ElevatedButton.icon(
                              onPressed:
                                  widget.isPlaylist ? playNext : playPrevious,
                              icon: const Icon(Icons.skip_next),
                              label: const Text("Next"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
  }
}
