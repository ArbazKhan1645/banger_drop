import 'dart:ui';
import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/notifications/fcm_notification_sender.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:html_unescape/html_unescape.dart';

class SocialPostWidget extends StatefulWidget {
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
  final description;
  final VoidCallback onTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;
  final VoidCallback onLikeInfoTap;
  final VoidCallback onshareInfoTap;
  final VoidCallback ProfileTap;

  const SocialPostWidget({
    super.key,
    required this.bangerId,
    required this.bangerImg,
    required this.ownerID,
    required this.currentUserId,
    required this.artistImageUrl,
    required this.songImageUrl,
    required this.artistName,
    required this.songName,
    this.playlistName,
    required this.timeAgo,
    required this.comments,
    required this.shares,
    required this.onTap,
    this.playlistDropped = false,
    required this.onCommentTap,
    required this.onShareTap,
    required this.onLikeInfoTap,
    required this.onshareInfoTap,
    required this.ProfileTap,
    required this.description,
  });

  @override
  State<SocialPostWidget> createState() => _SocialPostWidgetState();
}

class _SocialPostWidgetState extends State<SocialPostWidget> {
  final FcmNotificationSender sender = FcmNotificationSender();
  bool _isExpanded = false;

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

  Future<void> _awardPoints({
    required String userId,
    required int points,
    required String source,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(userId);
    final logRef = userRef.collection('pointsLog').doc();

    final batch = firestore.batch();
    final now = Timestamp.now();

    batch.update(userRef, {'points': FieldValue.increment(points)});

    batch.set(logRef, {'points': points, 'source': source, 'timestamp': now});

    await batch.commit();
  }

  bool isLiked = false;
  int likeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialLikeState();
  }

  Future<void> _loadInitialLikeState() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('Bangers')
            .doc(widget.bangerId)
            .get();

    if (doc.exists) {
      final data = doc.data()!;
      final likes = List<Map<String, dynamic>>.from(data['Likes'] ?? []);
      final total = data['TotalLikes'] ?? 0;

      setState(() {
        isLiked = likes.any((like) => like['id'] == widget.currentUserId);
        likeCount = total;
      });
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
  }

  String decodeHtmlEntities(String input) {
    final unescape = HtmlUnescape();
    return unescape.convert(input);
  }

  Future<void> _toggleLike() async {
    final ref = FirebaseFirestore.instance
        .collection('Bangers')
        .doc(widget.bangerId);

    bool addedLike = false;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final likes = List<Map<String, dynamic>>.from(data['Likes'] ?? []);
      int totalLikes = data['TotalLikes'] ?? 0;

      final alreadyLiked = likes.any(
        (like) => like['id'] == widget.currentUserId,
      );

      final userData = FirebaseFirestore.instance
          .collection('users')
          .doc(data['CreatedBy']);

      if (alreadyLiked) {
        likes.removeWhere((like) => like['id'] == widget.currentUserId);
        totalLikes = (totalLikes > 0) ? totalLikes - 1 : 0;
        setState(() {
          isLiked = false;
          likeCount = totalLikes;
        });
      } else {
        final currentUserName = AppConstants.userName;
        likes.add({
          'id': widget.currentUserId,
          'name': currentUserName,
          'time': DateTime.now().toIso8601String(),
          'img': AppConstants.userImg,
        });
        totalLikes += 1;
        addedLike = true; // track for notification

        setState(() {
          isLiked = true;
          likeCount = totalLikes;
        });
      }

      if (totalLikes == 10) {
        await _awardPoints(
          userId: data['CreatedBy'],
          points: 5,
          source: 'like-10',
        );
      } else if (totalLikes == 50) {
        await _awardPoints(
          userId: data['CreatedBy'],
          points: 10,
          source: 'like-50',
        );
      } else if (totalLikes == 100) {
        await _awardPoints(
          userId: data['CreatedBy'],
          points: 50,
          source: 'like-100',
        );
      } else if (totalLikes % 500 == 0 && totalLikes > 0) {
        await _awardPoints(
          userId: data['CreatedBy'],
          points: 50,
          source: 'like-$totalLikes',
        );
      }

      transaction.update(ref, {'Likes': likes, 'TotalLikes': totalLikes});
    });

    if (await fetchNotificationPreference('social', widget.ownerID)) {
      final targetToken = await sender.fetchFcmTokensForUser(widget.ownerID);
      // ✅ Call notification after transaction
      if (addedLike && widget.currentUserId != widget.ownerID) {
        await addNotification(
          userImg: AppConstants.userImg,
          bangerImg: widget.bangerImg ?? '',
          bangerId: widget.bangerId,
          bangerOwnerId: widget.ownerID,
          actionType: 'like',
          userId: widget.currentUserId,
          userName: AppConstants.userName,
        );

        for (String token in targetToken) {
          await sender.sendNotification(
            title: "Banger Liked ❤️",
            body: "${AppConstants.userName} liked Your banger",
            targetToken: token,
            dataPayload: {"type": "social"},
            uid: widget.ownerID,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('Bangers')
              .doc(widget.bangerId)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final likes = List<Map<String, dynamic>>.from(data['Likes'] ?? []);
        final totalLikes = data['TotalLikes'] ?? 0;
        final totalShares = data['TotalShares'] ?? 0;

        isLiked = likes.any((like) => like['id'] == widget.currentUserId);
        likeCount = totalLikes;

        return GestureDetector(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 🔼 ...keep your top layout here unchanged
                      /// Top section: Artist, song image and info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                widget.ProfileTap();
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    widget.artistImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => const Icon(
                                          Icons.person,
                                          color: Colors.grey,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.artistName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  widget.playlistDropped
                                      ? 'Dropped a playlist!'
                                      : 'Dropped a banger!',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        imageUrl: widget.songImageUrl,
                                        width: 50.w,
                                        height: 50.h,
                                        fit: BoxFit.cover,
                                        placeholder:
                                            (context, url) => Container(
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.music_note,
                                              ),
                                            ),
                                        errorWidget:
                                            (context, url, error) => Container(
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.music_note,
                                              ),
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            decodeHtmlEntities(widget.songName),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15.sp,
                                              color: Colors.white,
                                            ),
                                          ),
                                          if (widget.playlistName != null)
                                            Text(
                                              widget.playlistName!,
                                              style: appThemes.small.copyWith(
                                                // fontFamily: 'Sans',
                                                color: appColors.textGrey,
                                              ),
                                            ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                decodeHtmlEntities(
                                                  widget.description ?? '',
                                                ),
                                                maxLines:
                                                    _isExpanded ? null : 3,
                                                overflow:
                                                    _isExpanded
                                                        ? TextOverflow.visible
                                                        : TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              if ((widget.description ?? '')
                                                      .length >
                                                  100) // Adjust based on needs
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _isExpanded =
                                                          !_isExpanded;
                                                    });
                                                  },
                                                  child: Text(
                                                    _isExpanded
                                                        ? 'Show less'
                                                        : 'Show more',
                                                    style: TextStyle(
                                                      fontSize: 13.sp,
                                                      color: Colors.pinkAccent,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      /// Time & Icon Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '',
                            style: TextStyle(
                              color: Colors.pinkAccent,
                              fontWeight: FontWeight.w500,
                              fontSize: 13.sp,
                            ),
                          ),
                          Wrap(
                            alignment: WrapAlignment.end,
                            children: [
                              IconButton(
                                onPressed: _toggleLike,
                                icon: Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isLiked ? Colors.red : Colors.white,
                                  size: 25.sp,
                                ),
                              ),
                              IconButton(
                                onPressed: widget.onCommentTap,
                                icon: Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                              IconButton(
                                onPressed: widget.onShareTap,
                                icon: Icon(
                                  Icons.share_outlined,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      /// ✅ Real-time likes and shares display
                      Row(
                        children: [
                          Text(
                            widget.timeAgo,
                            style: TextStyle(
                              color: Colors.pinkAccent,
                              fontWeight: FontWeight.w500,
                              fontSize: 13.sp,
                            ),
                          ),
                          Spacer(),
                          GestureDetector(
                            onTap: widget.onLikeInfoTap,
                            child: Text(
                              '$totalLikes likes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: widget.onshareInfoTap,
                            child: Text(
                              '$totalShares shares',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
