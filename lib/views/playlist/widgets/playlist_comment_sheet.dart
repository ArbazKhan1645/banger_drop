import 'package:banger_drop/notifications/fcm_notification_sender.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:banger_drop/consts/consts.dart';

class PlaylistCommentsBottomSheet extends StatefulWidget {
  final String playlistId;
  final String currentUserId;
  final String currentUserName;
  final String currentUserImg;
  final String ownerId;
  final String playlistName;
  final String playlistImg;

  const PlaylistCommentsBottomSheet({
    super.key,
    required this.playlistId,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserImg,
    required this.ownerId,
    required this.playlistImg,
    required this.playlistName,
  });

  @override
  State<PlaylistCommentsBottomSheet> createState() =>
      _PlaylistCommentsBottomSheetState();
}

class _PlaylistCommentsBottomSheetState
    extends State<PlaylistCommentsBottomSheet> {
  final TextEditingController commentController = TextEditingController();
  final FcmNotificationSender sender = FcmNotificationSender();
  Future<bool> fetchNotificationPreference(String fieldName, String uid) async {
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

  Future<void> addComment(String commentText) async {
    if (commentText.trim().isEmpty) return;

    final commentData = {
      'text': commentText,
      'uid': widget.currentUserId,
      'name': widget.currentUserName,
      'img': widget.currentUserImg,
      'createdAt': Timestamp.now(),
    };

    final ref = FirebaseFirestore.instance
        .collection('Playlist')
        .doc(widget.playlistId);

    await ref.update({
      'comments': FieldValue.arrayUnion([commentData]),
      'TotalComments': FieldValue.increment(1),
    });

    commentController.clear();
    if (await fetchNotificationPreference('social', widget.ownerId)) {
      final targetToken = await sender.fetchFcmTokensForUser(widget.ownerId);

      if (widget.currentUserId != widget.ownerId) {
        await addNotification(
          bangerImg: widget.playlistImg,
          userImg: AppConstants.userImg,
          bangerId: widget.playlistId,
          bangerOwnerId: widget.ownerId,
          actionType: 'Playlistcomment',
          userId: widget.currentUserId,
          userName: AppConstants.userName,
        );
        for (String token in targetToken) {
          await sender.sendNotification(
            title: "Playlist Comments",
            body: "${AppConstants.userName} commentd on your Playlist",
            targetToken: token,
            dataPayload: {"type": "social"},
            uid: widget.ownerId,
          );
        }
      }
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500.h,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.purple,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Text('Comments', style: appThemes.Medium),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('Playlist')
                      .doc(widget.playlistId)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final comments = List<Map<String, dynamic>>.from(
                  data?['comments'] ?? [],
                );

                if (comments.isEmpty) {
                  return const Center(
                    child: Text(
                      'No comments yet',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[300],
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: comment['img'] ?? '',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => const Icon(
                                  Icons.person,
                                  size: 24,
                                  color: Colors.grey,
                                ),
                            errorWidget:
                                (context, url, error) => const Icon(
                                  Icons.person,
                                  size: 24,
                                  color: Colors.grey,
                                ),
                          ),
                        ),
                      ),

                      title: Text(
                        comment['name'] ?? 'User',
                        style: appThemes.small,
                      ),
                      subtitle: Text(
                        comment['text'] ?? '',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => addComment(commentController.text),
                icon: const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
