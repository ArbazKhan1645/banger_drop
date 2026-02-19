import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/helper/shared_prefrences_helper.dart';
import 'package:banger_drop/notifications/fcm_notification_sender.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BangerActionsBar extends StatefulWidget {
  final String bangerId;
  final String ownerID;
  final String currentUserId;
  final String? bangerImg;
  final String timeAgo;
  final int shares;

  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;
  final VoidCallback onLikeInfoTap;
  final VoidCallback onshareInfoTap;

  const BangerActionsBar({
    super.key,
    required this.bangerId,
    required this.ownerID,
    required this.currentUserId,
    required this.bangerImg,
    required this.timeAgo,
    required this.shares,
    required this.onCommentTap,
    required this.onShareTap,
    required this.onLikeInfoTap,
    required this.onshareInfoTap,
  });

  @override
  State<BangerActionsBar> createState() => _BangerActionsBarState();
}

class _BangerActionsBarState extends State<BangerActionsBar> {
  final FcmNotificationSender sender = FcmNotificationSender();

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

  bool isLiked = false;
  int likeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialLikeState();
    _loadFavoriteStatus();
  }

  @override
  void didUpdateWidget(covariant BangerActionsBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the bangerId has changed, reload the favorite status
    if (oldWidget.bangerId != widget.bangerId) {
      _loadFavoriteStatus();
    }
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

  bool isFavorite = false;
  Future<void> _loadFavoriteStatus() async {
    await SharedPreferencesHelper.init();
    List<String> favList = SharedPreferencesHelper.getStringList('fav') ?? [];

    setState(() {
      isFavorite = favList.contains(widget.bangerId);
    });
  }

  Future<void> _toggleFavorite() async {
    List<String> favList = SharedPreferencesHelper.getStringList('fav') ?? [];
    print(widget.bangerId);
    print(
      '================================---======================----==================',
    );
    setState(() {
      if (isFavorite) {
        favList.remove(widget.bangerId);
        isFavorite = false;
      } else {
        favList.add(widget.bangerId);
        isFavorite = true;
      }
    });

    await SharedPreferencesHelper.setStringList('fav', favList);
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
        likes.add({
          'id': widget.currentUserId,
          'name': AppConstants.userName,
          'time': DateTime.now().toIso8601String(),
          'img': AppConstants.userImg,
        });
        totalLikes += 1;
        addedLike = true;
        setState(() {
          isLiked = true;
          likeCount = totalLikes;
        });
      }

      transaction.update(ref, {'Likes': likes, 'TotalLikes': totalLikes});

      if (totalLikes == 10)
        userData.update({'points': FieldValue.increment(5)});
      else if (totalLikes == 50)
        userData.update({'points': FieldValue.increment(10)});
      else if (totalLikes == 100)
        userData.update({'points': FieldValue.increment(50)});
      else if (totalLikes % 500 == 0 && totalLikes > 0) {
        userData.update({'points': FieldValue.increment(50)});
      }
    });

    if (await fetchNotificationPreference('social', widget.ownerID)) {
      final targetToken = await sender.fetchFcmTokensForUser(widget.ownerID);

      if (addedLike && widget.currentUserId != widget.ownerID) {
        await FirebaseFirestore.instance.collection('notifications').add({
          "bangerId": widget.bangerId,
          "bangerOwnerId": widget.ownerID,
          "type": 'like',
          "users": [
            {
              "uid": widget.currentUserId,
              "name": AppConstants.userName,
              "img": AppConstants.userImg,
            },
          ],
          "bangerImg": widget.bangerImg,
          "timestamp": Timestamp.now(),
          "seenBy": [], // when creating a new notification
        });
      }

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
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final totalLikes = data['TotalLikes'] ?? 0;
        final totalShares = data['TotalShares'] ?? 0;
        final likes = List<Map<String, dynamic>>.from(data['Likes'] ?? []);
        final isCurrentlyLiked = likes.any(
          (like) => like['id'] == widget.currentUserId,
        );

        return Column(
          children: [
            Row(
              children: [
                Text(
                  widget.timeAgo,
                  style: const TextStyle(color: Colors.pinkAccent),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onLikeInfoTap,
                  child: Text(
                    '$totalLikes likes',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: widget.onshareInfoTap,
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
                  onPressed: _toggleLike,
                  icon: Icon(
                    isCurrentlyLiked ? Icons.favorite : Icons.favorite_border,
                    color: isCurrentlyLiked ? Colors.red : Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: widget.onCommentTap,
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: widget.onShareTap,
                  icon: const Icon(Icons.share_outlined, color: Colors.white),
                ),
                Spacer(),
                IconButton(
                  onPressed: _toggleFavorite,
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: appColors.white,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
