import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/Explore/widgets/comments_widget.dart';
import 'package:banger_drop/views/Explore/widgets/like_widget.dart';
import 'package:banger_drop/views/VideoPlayer/youtube_player.dart';
import 'package:banger_drop/views/artist_profile/artist_profile_view.dart';
import 'package:banger_drop/views/chat/controller/chat_controller.dart';
import 'package:banger_drop/views/playlist/playlist_view.dart';
import 'package:banger_drop/views/single_audio_player/single_player_view.dart';
import 'package:banger_drop/views/widgets/loading_widget.dart';
import 'package:banger_drop/views/widgets/share_audio_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_typedefs/rx_typedefs.dart';
import 'package:just_audio/just_audio.dart';
import 'package:banger_drop/consts/consts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../Explore/widgets/share_widget.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String name;
  final String imgUrl;

  ChatScreen({
    super.key,
    required this.userId,
    required this.name,
    required this.imgUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController controller = Get.put(ChatController());
  bool _hasScrolledToBottom = false; // Add this flag

  @override
  void initState() {
    super.initState();

    controller.initialize(widget.userId);
    controller.markMessagesAsRead();

    // Ensure block status is loaded before UI build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.checkBlockStatus(widget.userId);
      // Don't scroll here - let the StreamBuilder handle initial scroll
    });
  }

  void _scrollToBottom({bool force = false}) {
    // Add a small delay to ensure ListView is fully rendered
    Future.delayed(const Duration(milliseconds: 50), () {
      if (controller.scrollController.hasClients) {
        final maxScroll = controller.scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          // Only scroll if there's content
          controller.scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _scrollToBottomInstant() {
    // For initial load, use jumpTo for instant scroll
    Future.delayed(const Duration(milliseconds: 100), () {
      if (controller.scrollController.hasClients) {
        final maxScroll = controller.scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          controller.scrollController.jumpTo(maxScroll);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Picture1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            if (!controller.isBlockStatusChecked.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.isBlockedByOther.value) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "User not found",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.back();
                      },
                      child: Text('Go back'),
                    ),
                  ],
                ),
              );
            }

            if (controller.isBlockedByYou.value) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "You have blocked this user",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.back();
                      },
                      child: Text('Go back'),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Get.back();
                        },
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                TopBarWidget(
                  name: widget.name,
                  Url: widget.imgUrl,
                  profileTap: () {
                    Get.to(() => ArtistProfileView(userId: widget.userId));
                  },
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: controller.messageStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data!.docs;

                      // Handle scrolling logic
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!_hasScrolledToBottom) {
                          // First time loading - scroll instantly to bottom
                          _scrollToBottomInstant();
                          _hasScrolledToBottom = true;
                        } else {
                          // New messages arrived - animate to bottom
                          _scrollToBottom();
                        }
                      });

                      return ListView.builder(
                        controller: controller.scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final doc = messages[index];
                          final docId = doc.id;
                          final msg = doc.data() as Map<String, dynamic>;
                          final isMe =
                              msg['senderId'] == controller.currentUserId;
                          final type = msg['type'] ?? 'text';
                          final likedBy = msg['likedBy'] ?? [];
                          final messageId = doc.id;

                          if (type == 'audio') {
                            return AudioMessageBubble(
                              img: msg['img'] ?? '',
                              bangerId: msg['bangerId'] ?? '',
                              url: msg['audioUrl'],
                              title: msg['title'] ?? 'Audio Message',
                              isMe: isMe,
                              chatId: controller.chatId,
                              messageId: messageId,
                              likedBy: likedBy,
                            );
                          }

                          if (type == 'playlist') {
                            return PlaylistMessageBubble(
                              messageId: docId,
                              chatId: controller.chatId,
                              ontap: () {
                                Get.to(
                                  () => PlaylistView(
                                    playlistId: msg['playlistId'],
                                  ),
                                );
                              },
                              title: msg['title'],
                              imageUrl: msg['imageUrl'],
                              isMe: isMe,
                              likedBy: likedBy,
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: MessageBubble(
                              message: msg['text'] ?? '',
                              isMe: isMe,
                              chatId: controller.chatId,
                              messageId: messageId,
                              likedBy: likedBy,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Obx(() {
                  if (!controller.canSendMessage.value) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "This user's inbox is private. Follow them to send messages.",
                        style: TextStyle(
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  }

                  return ChatInputField(
                    hint: 'chat...',
                    controller: controller.messageController,
                    isSending: controller.isSending.value,
                    onSend: () {
                      controller.sendMessage().then((val) {
                        controller.sendMessageNotification(
                          AppConstants.userId,
                          widget.userId,
                          AppConstants.userImg,
                          AppConstants.userName,
                        );
                        // Scroll to bottom after sending message
                        _scrollToBottom();
                      });
                    },
                  );
                }),
              ],
            );
          }),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hasScrolledToBottom = false; // Reset flag on dispose
    super.dispose();
  }
}

class TopBarWidget extends StatefulWidget {
  const TopBarWidget({
    super.key,
    required,
    required this.name,
    this.Url,
    required this.profileTap,
  });
  final name;
  final Url;
  final Callback profileTap;

  @override
  State<TopBarWidget> createState() => _TopBarWidgetState();
}

class _TopBarWidgetState extends State<TopBarWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShaderMask(
                shaderCallback:
                    (bounds) => const LinearGradient(
                      colors: [Color(0xFF9A1BEA), Color(0xFFFF38B3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                blendMode: BlendMode.srcIn,
                child: SizedBox(
                  width: 250.w,
                  child: Text(
                    overflow: TextOverflow.ellipsis,
                    widget.name,
                    style: TextStyle(
                      fontSize: 27.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  widget.profileTap();
                },
                child: Container(
                  width: 80.w,
                  height:
                      80.w, // Use same value for width & height for perfect circle
                  padding: const EdgeInsets.all(3), // Space for the border
                  decoration: const BoxDecoration(
                    color: Colors.pinkAccent, // Border color
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: widget.Url,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 30),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatefulWidget {
  final String message;
  final bool isMe;
  final String messageId;
  final String chatId;
  final List<dynamic> likedBy;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.messageId,
    required this.chatId,
    required this.likedBy,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  bool _showHeart = false;
  bool _showMeta = false;
  bool _showTimestamp = false;

  late AnimationController _heartController;
  late Animation<double> _heartScaleAnim;

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  double _dragDx = 0;
  final double _swipeThreshold = 20.0;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heartScaleAnim = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  bool get isLiked => widget.likedBy.contains(currentUserId);

  void _handleDoubleTap() async {
    HapticFeedback.lightImpact();
    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(widget.messageId);

    await messageRef.update({
      'likedBy':
          isLiked
              ? FieldValue.arrayRemove([currentUserId])
              : FieldValue.arrayUnion([currentUserId]),
    });

    setState(() => _showHeart = true);
    _heartController.forward(from: 0);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _dragDx = 0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _dragDx += details.primaryDelta ?? 0;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.isMe && _dragDx <= -_swipeThreshold) {
      setState(() => _showTimestamp = true);
    } else if (!widget.isMe && _dragDx >= _swipeThreshold) {
      setState(() => _showTimestamp = true);
    } else {
      setState(() => _showTimestamp = false);
    }
    _dragDx = 0;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      onTap: () => setState(() => _showMeta = !_showMeta),
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment:
                widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isMe ? appColors.purple : appColors.pink,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(widget.isMe ? 16 : 0),
                    bottomRight: Radius.circular(widget.isMe ? 0 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.message,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontFamily: 'Sans',
                        color: Colors.white,
                      ),
                    ),
                    if (_showTimestamp || (widget.isMe && _showMeta))
                      StreamBuilder<DocumentSnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('chats')
                                .doc(widget.chatId)
                                .collection('messages')
                                .doc(widget.messageId)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          if (data == null) return const SizedBox();

                          final ts = data['timestamp'];
                          final isReadBy = List<String>.from(
                            data['isReadBy'] ?? [],
                          );
                          final isSeen = isReadBy.any(
                            (id) => id != currentUserId,
                          );

                          final timeStr =
                              ts is Timestamp
                                  ? _formatTime(ts.toDate())
                                  : 'Sending...';

                          Icon? icon;
                          if (!widget.isMe) {
                            // Don't show status icon for received messages
                            icon = null;
                          } else if (ts == null) {
                            icon = const Icon(
                              Icons.schedule,
                              color: Colors.white60,
                              size: 16,
                            );
                          } else if (isSeen) {
                            icon = const Icon(
                              Icons.done_all,
                              color: Colors.blueAccent,
                              size: 16,
                            );
                          } else {
                            icon = const Icon(
                              Icons.done_all,
                              color: Colors.white70,
                              size: 16,
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.white70,
                                  ),
                                ),
                                if (icon != null) ...[
                                  const SizedBox(width: 4),
                                  icon,
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ❤️ Like indicator
          if (isLiked)
            Positioned(
              bottom: 4,
              left: widget.isMe ? null : 5,
              right: widget.isMe ? 8 : null,
              child: const Icon(
                Icons.favorite,
                size: 16,
                color: Colors.redAccent,
              ),
            ),

          // ❤️ Double-tap animation
          if (_showHeart)
            ScaleTransition(
              scale: _heartScaleAnim,
              child: Icon(Icons.favorite, color: Colors.redAccent, size: 40.sp),
            ),
        ],
      ),
    );
  }
}

class ChatInputField extends StatefulWidget {
  final VoidCallback onSend;
  final String hint;
  final TextEditingController controller;
  final bool isSending;

  const ChatInputField({
    super.key,
    required this.onSend,
    required this.controller,
    required this.hint,
    required this.isSending,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: appColors.pink.withOpacity(.4),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                maxLines: 4,
                minLines: 1,
                controller: widget.controller,
                enabled: !widget.isSending, // Optional: disable while sending
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: appThemes.Medium.copyWith(
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Sans',
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            widget.isSending
                ? SizedBox(
                  width: 24,
                  height: 24,
                  child: LoadingWidget(color: appColors.white),
                )
                : IconButton(
                  onPressed: widget.onSend,
                  icon: Image.asset(
                    'assets/images/Send.png',
                    width: 30.w,
                    height: 30.h,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class AudioMessageBubble extends StatefulWidget {
  final String bangerId;
  final String chatId;
  final String messageId;
  final String url;
  final String title;
  final bool isMe;
  final List likedBy;
  final img;

  const AudioMessageBubble({
    super.key,
    required this.bangerId,
    required this.chatId,
    required this.messageId,
    required this.url,
    required this.title,
    required this.isMe,
    required this.likedBy,
    required this.img,
  });

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _player;
  bool _isPlaying = false;
  bool _isCompleted = false;
  bool _isLoading = false;
  bool _showMeta = false;

  bool _showHeart = false;
  late AnimationController _heartController;
  late Animation<double> _heartScaleAnim;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  double _dragDx = 0;
  final double _swipeThreshold = 20.0;
  bool _showTimestamp = false;

  bool get isLiked => widget.likedBy.contains(currentUserId);

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heartScaleAnim = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );
  }

  Future<void> _initAudio() async {
    try {
      setState(() => _isLoading = true);
      await _player.setUrl(widget.url);

      _player.playerStateStream.listen((state) {
        if (!mounted) return;
        final playing = state.playing;
        final completed = state.processingState == ProcessingState.completed;

        if (completed) {
          setState(() {
            _isPlaying = false;
            _isCompleted = true;
          });
          _player.seek(Duration.zero);
        } else {
          setState(() => _isPlaying = playing);
        }
      });
    } catch (e) {
      debugPrint('Audio load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _togglePlayPause() async {
    try {
      final bangerDoc =
          await FirebaseFirestore.instance
              .collection('Bangers')
              .doc(widget.bangerId)
              .get();

      if (!bangerDoc.exists) {
        // Show dialog if the song doesn't exist
        Get.dialog(
          AlertDialog(
            backgroundColor: appColors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.all(20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  "Song not found, Deleted By Artist",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
        return;
      }

      final data = bangerDoc.data()!;
      final isYoutube =
          data.containsKey('youtubeSong') && data['youtubeSong'] == true;

      if (isYoutube) {
        String? link = data['audioUrl'];
        if (data['isRawLink'] == true && link != null) {
          link = YoutubePlayer.convertUrlToId(link);
        }

        Get.to(
          () => YoutubePlayerScreen(
            videoUrl: link ?? '',
            bangerId: data['id'],
            ownerID: data['CreatedBy'] ?? '',
            currentUserId: AppConstants.userId,
            bangerImg: data['imageUrl'] ?? '',
            artistImageUrl: '',
            songImageUrl: data['imageUrl'] ?? '',
            artistName: '',
            songName: data['title'] ?? '',
            playlistName:
                data['playlistName'] == 'Select'
                    ? ''
                    : data['playlistName'] ?? '',
            timeAgo: getTimeAgoFromTimestamp(data['createdAt']),
            comments: data['TotalComments'] ?? 0,
            shares: data['TotalShares'] ?? 0,
            playlistDropped: data['playlistName'] != 'Select',
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
                    List<Map<String, dynamic>>.from(data['Likes'] ?? []);
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
            ProfileTap: () {
              Get.to(() => ArtistProfileView(userId: data['CreatedBy'] ?? ''));
            },
          ),
        );
      } else {
        Get.to(
          () => SingleBangerPlayerView(
            bangers: [
              {
                'artist': data['artist'],
                'audioUrl': data['audioUrl'],
                'id': data['id'],
                'imageUrl': data['imageUrl'],
                'isRawLink': false,
                'youtubeSong': false,
              },
            ],
            currentIndex: 0,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling play: $e');
      Get.snackbar("Error", "Something went wrong while opening the song.");
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

  void _handleDoubleTap() async {
    HapticFeedback.lightImpact();

    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(widget.messageId);

    await messageRef.update({
      'likedBy':
          isLiked
              ? FieldValue.arrayRemove([currentUserId])
              : FieldValue.arrayUnion([currentUserId]),
    });

    setState(() => _showHeart = true);
    _heartController.forward(from: 0);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _dragDx += details.primaryDelta ?? 0;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.isMe) {
      if (_dragDx <= -_swipeThreshold) {
        setState(() => _showTimestamp = true);
      } else {
        setState(() => _showTimestamp = false);
      }
    } else {
      if (_dragDx >= _swipeThreshold) {
        setState(() => _showTimestamp = true);
      } else {
        setState(() => _showTimestamp = false);
      }
    }
    _dragDx = 0;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showMeta = !_showMeta),
      onDoubleTap: _handleDoubleTap,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment:
                widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: widget.isMe ? appColors.purple : appColors.pink,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      widget.img == null || widget.img == ''
                          ? const Icon(Icons.audiotrack, color: Colors.white)
                          : Image.network(
                            widget.img,
                            fit: BoxFit.cover,
                            width: 50, // adjust size as needed
                            height: 50,
                          ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: appThemes.small.copyWith(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: _togglePlayPause,
                          ),
                    ],
                  ),
                  if (_showTimestamp)
                    FutureBuilder<DocumentSnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('chats')
                              .doc(widget.chatId)
                              .collection('messages')
                              .doc(widget.messageId)
                              .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        final ts = data?['timestamp'];
                        if (ts == null || ts is! Timestamp) {
                          return const SizedBox();
                        }
                        final time = _formatTime(ts.toDate());
                        return Text(
                          time,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10.sp,
                          ),
                        );
                      },
                    ),
                  if (_showMeta && widget.isMe)
                    StreamBuilder<DocumentSnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('chats')
                              .doc(widget.chatId)
                              .collection('messages')
                              .doc(widget.messageId)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        if (data == null) return const SizedBox();

                        final ts = data['timestamp'];
                        final isReadBy = List<String>.from(
                          data['isReadBy'] ?? [],
                        );
                        final isSeen = isReadBy.any(
                          (id) => id != currentUserId,
                        );

                        final timeStr =
                            ts is Timestamp
                                ? _formatTime(ts.toDate())
                                : 'Sending...';

                        Icon? icon;
                        if (ts == null) {
                          icon = const Icon(
                            Icons.schedule,
                            color: Colors.white60,
                            size: 16,
                          );
                        } else if (isSeen) {
                          icon = const Icon(
                            Icons.done_all,
                            color: Colors.blueAccent,
                            size: 16,
                          );
                        } else {
                          icon = const Icon(
                            Icons.done_all,
                            color: Colors.white70,
                            size: 16,
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 4),
                              icon,
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          if (isLiked)
            Positioned(
              bottom: 4,
              right: 8,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Icon(Icons.favorite, size: 16, color: Colors.redAccent),
              ),
            ),
          if (_showHeart)
            ScaleTransition(
              scale: _heartScaleAnim,
              child: Icon(Icons.favorite, color: Colors.redAccent, size: 40.sp),
            ),
        ],
      ),
    );
  }
}

class AudioPlayerManager {
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;

  AudioPlayerManager._internal();

  AudioPlayer? _currentPlayer;

  void setActivePlayer(AudioPlayer player) {
    if (_currentPlayer != null && _currentPlayer != player) {
      _currentPlayer!.stop();
    }
    _currentPlayer = player;
  }

  void disposePlayer(AudioPlayer player) {
    if (_currentPlayer == player) {
      _currentPlayer = null;
    }
  }
}

class PlaylistMessageBubble extends StatefulWidget {
  final String title;
  final String imageUrl;
  final bool isMe;
  final VoidCallback ontap;
  final String chatId;
  final String messageId;
  final List<dynamic> likedBy;
  // final id;

  const PlaylistMessageBubble({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.isMe,
    required this.ontap,
    required this.chatId,
    required this.messageId,
    required this.likedBy,
    // required this.id,
  });

  @override
  State<PlaylistMessageBubble> createState() => _PlaylistMessageBubbleState();
}

class _PlaylistMessageBubbleState extends State<PlaylistMessageBubble>
    with SingleTickerProviderStateMixin {
  bool _showMeta = false;
  bool _showHeart = false;
  bool _showTimestamp = false;
  double _dragDx = 0;
  final double _swipeThreshold = 20.0;

  late AnimationController _heartController;
  late Animation<double> _heartScaleAnim;

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  bool get isLiked => widget.likedBy.contains(currentUserId);

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heartScaleAnim = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() async {
    HapticFeedback.lightImpact();

    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(widget.messageId);

    await messageRef.update({
      'likedBy':
          isLiked
              ? FieldValue.arrayRemove([currentUserId])
              : FieldValue.arrayUnion([currentUserId]),
    });

    setState(() => _showHeart = true);
    _heartController.forward(from: 0);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _dragDx = 0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _dragDx += details.primaryDelta ?? 0;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.isMe && _dragDx <= -_swipeThreshold) {
      setState(() => _showTimestamp = true);
    } else if (!widget.isMe && _dragDx >= _swipeThreshold) {
      setState(() => _showTimestamp = true);
    } else {
      setState(() => _showTimestamp = false);
    }
    _dragDx = 0;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      onTap: () => setState(() => _showMeta = !_showMeta),
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment:
                widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isMe ? appColors.purple : appColors.pink,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: widget.imageUrl,
                              width: 70.w,
                              height: 70.h,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 24,
                                  ),
                            ),
                          ),
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkResponse(
                                onTap: widget.ontap,
                                containedInkWell: true,
                                highlightShape: BoxShape.rectangle,
                                splashColor: Colors.white24,
                                child: const Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 8),
                      Text(
                        'Playlist: ${widget.title}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_showTimestamp || (widget.isMe && _showMeta))
                    StreamBuilder<DocumentSnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('chats')
                              .doc(widget.chatId)
                              .collection('messages')
                              .doc(widget.messageId)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        if (data == null) return const SizedBox();

                        final ts = data['timestamp'];
                        final isReadBy = List<String>.from(
                          data['isReadBy'] ?? [],
                        );
                        final isSeen = isReadBy.any(
                          (id) => id != currentUserId,
                        );

                        final timeStr =
                            ts is Timestamp
                                ? _formatTime(ts.toDate())
                                : 'Sending...';

                        Icon? icon;
                        if (!widget.isMe) {
                          icon = null;
                        } else if (ts == null) {
                          icon = const Icon(
                            Icons.schedule,
                            color: Colors.white60,
                            size: 16,
                          );
                        } else if (isSeen) {
                          icon = const Icon(
                            Icons.done_all,
                            color: Colors.blueAccent,
                            size: 16,
                          );
                        } else {
                          icon = const Icon(
                            Icons.done_all,
                            color: Colors.white70,
                            size: 16,
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                              if (icon != null) ...[
                                const SizedBox(width: 4),
                                icon,
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // ❤️ Static like heart
          if (isLiked)
            Positioned(
              bottom: 4,
              left: widget.isMe ? null : 6,
              right: widget.isMe ? 8 : null,
              child: const Icon(
                Icons.favorite,
                size: 16,
                color: Colors.redAccent,
              ),
            ),

          // ❤️ Like animation
          if (_showHeart)
            ScaleTransition(
              scale: _heartScaleAnim,
              child: Icon(Icons.favorite, color: Colors.redAccent, size: 40),
            ),
        ],
      ),
    );
  }
}
