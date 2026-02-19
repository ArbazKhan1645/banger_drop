import 'package:banger_drop/consts/consts.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class FollowNotificationsScreen extends StatefulWidget {
  const FollowNotificationsScreen({super.key});

  @override
  State<FollowNotificationsScreen> createState() =>
      _FollowNotificationsScreenState();
}

class _FollowNotificationsScreenState extends State<FollowNotificationsScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .collection('notifications')
              .where('type', isEqualTo: 'follow_request')
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.pink),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No new notifications',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return FollowRequestNotificationTile(
              notificationId: doc.id,
              fromUserId: data['fromUserId'],
              timestamp: data['timestamp'],
              status: data['status'] ?? 'pending',
              currentUserId: currentUserId,
            );
          },
        );
      },
    );
  }
}

class FollowRequestNotificationTile extends StatefulWidget {
  final String notificationId;
  final String fromUserId;
  final Timestamp timestamp;
  final String status;
  final String currentUserId;

  const FollowRequestNotificationTile({
    super.key,
    required this.notificationId,
    required this.fromUserId,
    required this.timestamp,
    required this.status,
    required this.currentUserId,
  });

  @override
  State<FollowRequestNotificationTile> createState() =>
      _FollowRequestNotificationTileState();
}

class _FollowRequestNotificationTileState
    extends State<FollowRequestNotificationTile> {
  bool _isProcessing = false;

  Future<void> _acceptFollowRequest() async {
    setState(() => _isProcessing = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final now = DateTime.now();

      final followersRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('followers')
          .doc(widget.fromUserId);

      final followingRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.fromUserId)
          .collection('following')
          .doc(widget.currentUserId);

      final requestRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('followRequests')
          .doc(widget.fromUserId);

      final notificationRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('notifications')
          .doc(widget.notificationId);

      final acceptNotificationRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.fromUserId)
              .collection('notifications')
              .doc();

      batch.set(followersRef, {'timestamp': now});
      batch.set(followingRef, {'timestamp': now});
      batch.delete(requestRef);
      batch.update(notificationRef, {'status': 'accepted', 'acceptedAt': now});
      batch.set(acceptNotificationRef, {
        'type': 'follow_accepted',
        'fromUserId': widget.currentUserId,
        'timestamp': now,
        'message': 'accepted your follow request',
        'status': 'unread',
      });

      await batch.commit();

      Get.snackbar(
        'Success',
        'Follow request accepted!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to accept request',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteFollowRequest() async {
    setState(() => _isProcessing = true);

    try {
      final now = DateTime.now();
      final requestRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('followRequests')
          .doc(widget.fromUserId);

      final notificationRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('notifications')
          .doc(widget.notificationId);

      await requestRef.delete();
      await notificationRef.update({'status': 'deleted', 'deletedAt': now});

      Get.snackbar(
        'Deleted',
        'Follow request deleted',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete request',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _followBack() async {
    final now = DateTime.now();
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.fromUserId)
          .collection('followRequests')
          .doc(widget.currentUserId)
          .set({'timestamp': now});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.fromUserId)
          .collection('notifications')
          .add({
            'type': 'follow_request',
            'fromUserId': widget.currentUserId,
            'timestamp': now,
            'status': 'pending',
            'message': 'sent you a follow request',
          });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.fromUserId)
          .collection('notifications')
          .add({
            'type': 'follow_request',
            'fromUserId': widget.currentUserId,
            'timestamp': now,
            'status': 'sent',
            'message': 'sent you a follow request',
          });

      Get.snackbar(
        'Followed back',
        'You followed back the user',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to follow back',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<bool> _isFollowingBack() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserId)
            .collection('following')
            .doc(widget.fromUserId)
            .get();
    return doc.exists;
  }

  String _getTimeAgo(Timestamp timestamp) {
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inDays > 7) return '${diff.inDays ~/ 7}w ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'now';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.fromUserId)
              .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox();

        final name = userData['name'] ?? 'Unknown User';
        final image =
            userData['profileImage'] ?? 'https://i.stack.imgur.com/l60Hf.png';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25.r,
                backgroundColor: Colors.transparent,
                backgroundImage: CachedNetworkImageProvider(image),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name sent you a follow request',
                      style: appThemes.small,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTimeAgo(widget.timestamp),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (_isProcessing)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (widget.status == 'accepted')
                FutureBuilder(
                  future: Future.wait([
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.currentUserId)
                        .collection('following')
                        .doc(widget.fromUserId)
                        .get(),
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.fromUserId)
                        .collection('followRequests')
                        .doc(widget.currentUserId)
                        .get(),
                  ]),
                  builder: (
                    context,
                    AsyncSnapshot<List<DocumentSnapshot>> snap,
                  ) {
                    if (!snap.hasData) return const SizedBox();

                    final isFollowing = snap.data![0].exists;
                    final alreadyRequested = snap.data![1].exists;

                    if (isFollowing) {
                      return const Text(
                        "Following",
                        style: TextStyle(color: Colors.grey),
                      );
                    } else if (alreadyRequested) {
                      return const Text(
                        "Requested",
                        style: TextStyle(color: Colors.grey),
                      );
                    } else {
                      return ElevatedButton(
                        onPressed: _followBack,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: Text("Follow Back", style: appThemes.small),
                      );
                    }
                  },
                )
              else
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _acceptFollowRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                      ),
                      child: const Text(
                        "Accept",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _deleteFollowRequest,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Delete"),
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
