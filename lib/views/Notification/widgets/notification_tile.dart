import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowRequestNotificationTile extends StatefulWidget {
  final String notificationId;
  final String fromUserId;
  final String fromUserName;
  final String message;
  final DateTime timestamp;

  const FollowRequestNotificationTile({
    super.key,
    required this.notificationId,
    required this.fromUserId,
    required this.fromUserName,
    required this.message,
    required this.timestamp,
  });

  @override
  State<FollowRequestNotificationTile> createState() =>
      _FollowRequestNotificationTileState();
}

class _FollowRequestNotificationTileState
    extends State<FollowRequestNotificationTile> {
  bool isAccepted = false;
  bool isFollowedBack = false;

  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _acceptRequest() async {
    final now = DateTime.now();

    final batch = FirebaseFirestore.instance.batch();

    final currentUserDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId);
    final requesterDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.fromUserId);

    // Add to followers
    batch.set(currentUserDoc.collection('followers').doc(widget.fromUserId), {
      'followedAt': now,
    });

    // Remove the follow request
    batch.delete(
      currentUserDoc.collection('followRequests').doc(widget.fromUserId),
    );

    // Update notification status
    batch.update(
      currentUserDoc.collection('notifications').doc(widget.notificationId),
      {'status': 'accepted'},
    );

    await batch.commit();

    setState(() {
      isAccepted = true;
    });
  }

  Future<void> _deleteRequest() async {
    final batch = FirebaseFirestore.instance.batch();

    final currentUserDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId);

    // Remove the notification
    batch.delete(
      currentUserDoc.collection('notifications').doc(widget.notificationId),
    );

    // Remove follow request
    batch.delete(
      currentUserDoc.collection('followRequests').doc(widget.fromUserId),
    );

    await batch.commit();

    // Optionally, the sender can listen to this change to revert to Follow button
  }

  Future<void> _followBack() async {
    final now = DateTime.now();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.fromUserId)
        .collection('followRequests')
        .doc(currentUserId)
        .set({'requesterId': currentUserId, 'timestamp': now});

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.fromUserId)
        .collection('notifications')
        .add({
          'type': 'follow_request',
          'fromUserId': currentUserId,
          'timestamp': now,
          'message': 'sent you a follow request',
          'status': 'pending',
        });

    setState(() => isFollowedBack = true);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black12,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.person, color: Colors.pinkAccent),
        title: Text(
          widget.fromUserName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          widget.message,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing:
            isAccepted
                ? isFollowedBack
                    ? const Text(
                      'Requested',
                      style: TextStyle(color: Colors.white),
                    )
                    : TextButton(
                      onPressed: _followBack,
                      child: const Text('Follow Back'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.pink,
                        side: const BorderSide(color: Colors.pink),
                      ),
                    )
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: _acceptRequest,
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.redAccent),
                      onPressed: _deleteRequest,
                    ),
                  ],
                ),
      ),
    );
  }
}
