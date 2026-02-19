import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class NewNotificationScreen extends StatefulWidget {
  const NewNotificationScreen({super.key});

  @override
  State<NewNotificationScreen> createState() => _NewNotificationScreenState();
}

class _NewNotificationScreenState extends State<NewNotificationScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  Future<void> markFollowRequestsAsSeen() async {
    try {
      final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      // Get all pending follow requests
      final QuerySnapshot pendingRequests =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .collection('followRequests')
              .where('status', isEqualTo: 'pending')
              .get();

      if (pendingRequests.docs.isEmpty) return;

      // Create batch to update all pending requests
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (QueryDocumentSnapshot doc in pendingRequests.docs) {
        batch.update(doc.reference, {'seen': true, 'seenAt': DateTime.now()});
      }

      // Execute batch update
      await batch.commit();

      print('Marked ${pendingRequests.docs.length} follow requests as seen');
    } catch (e) {
      print('Error marking follow requests as seen: $e');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    markFollowRequestsAsSeen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 0, 0, 1),

      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/Picture1.png', // change to your image path
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              SizedBox(height: 50.h), // Adjust height as needed
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Follow Requests',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUserId)
                        .collection('followRequests')
                        .where('status', whereIn: ['pending', 'accepted'])
                        .orderBy('timestamp', descending: true)
                        .snapshots(),

                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.purple),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading requests',
                        style: TextStyle(color: Colors.white, fontSize: 16.sp),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 80.w,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No follow requests',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'When someone sends you a follow request,\nit will appear here',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 16.h,
                      ),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final requestDoc = snapshot.data!.docs[index];
                        final requesterId = requestDoc['requesterId'];

                        return FollowRequestWidget(
                          requesterId: requesterId,
                          currentUserId: currentUserId,
                          requestDocId: requestDoc.id,
                          timestamp: requestDoc['timestamp'] as Timestamp,
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Enum for follow request states
enum RequestState { loading, pending, accepted, followBack }

class FollowRequestWidget extends StatefulWidget {
  final String requesterId;
  final String currentUserId;
  final String requestDocId;
  final Timestamp timestamp;

  const FollowRequestWidget({
    super.key,
    required this.requesterId,
    required this.currentUserId,
    required this.requestDocId,
    required this.timestamp,
  });

  @override
  State<FollowRequestWidget> createState() => _FollowRequestWidgetState();
}

class _FollowRequestWidgetState extends State<FollowRequestWidget> {
  RequestState _state = RequestState.loading; // Start with loading state
  bool _isActionLoading = false; // Separate loading for actions
  Map<String, dynamic>? _requesterData;
  bool _isDataLoading = true; // Loading state for user data

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Combined initialization method
  Future<void> _initializeData() async {
    await Future.wait([_loadRequesterData(), _checkRequestState()]);

    if (mounted) {
      setState(() {
        _isDataLoading = false;
      });
    }
  }

  Future<void> _loadRequesterData() async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.requesterId)
              .get();

      if (userDoc.exists && mounted) {
        setState(() {
          _requesterData = userDoc.data();
        });
      }
    } catch (e) {
      print('Error loading requester data: $e');
      if (mounted) {
        setState(() {
          _requesterData = {'name': 'Unknown User'}; // Fallback data
        });
      }
    }
  }

  Future<void> _checkRequestState() async {
    try {
      final requestDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUserId)
              .collection('followRequests')
              .doc(widget.requestDocId)
              .get();

      if (!requestDoc.exists) {
        if (mounted) setState(() => _state = RequestState.pending);
        return;
      }

      final status = requestDoc['status'];

      // Check if current user is following the requester
      final isFollowingRequester =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUserId)
              .collection('following')
              .doc(widget.requesterId)
              .get();

      // Check if requester is following the current user
      final isRequesterFollowing =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUserId)
              .collection('followers')
              .doc(widget.requesterId)
              .get();

      RequestState newState;
      if (status == 'pending') {
        newState = RequestState.pending;
      } else if (status == 'accepted') {
        if (isFollowingRequester.exists && isRequesterFollowing.exists) {
          newState = RequestState.followBack; // mutual follow
        } else if (isRequesterFollowing.exists &&
            !isFollowingRequester.exists) {
          newState =
              RequestState
                  .accepted; // requester follows me, I haven't followed back
        } else {
          // Edge case: accepted status but no valid follower/following
          newState = RequestState.pending;
        }
      } else {
        newState = RequestState.pending;
      }

      if (mounted) {
        setState(() {
          _state = newState;
        });
      }
    } catch (e) {
      print('Error in _checkRequestState: $e');
      if (mounted) {
        setState(() {
          _state = RequestState.pending; // Default to pending on error
        });
      }
    }
  }

  Future<void> _acceptRequest() async {
    if (!mounted) return;
    setState(() => _isActionLoading = true);

    try {
      final now = DateTime.now();

      // Create mutual following relationship
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Add requester to current user's followers
      final currentUserFollowersRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('followers')
          .doc(widget.requesterId);

      batch.set(currentUserFollowersRef, {'timestamp': now});

      // Add current user to requester's following
      final requesterFollowingRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.requesterId)
          .collection('following')
          .doc(widget.currentUserId);

      batch.set(requesterFollowingRef, {'timestamp': now});

      // Update the follow request status
      final requestRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('followRequests')
          .doc(widget.requestDocId);

      batch.update(requestRef, {'status': 'accepted'});

      // Remove related notification
      final notifQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUserId)
              .collection('notifications')
              .where('type', isEqualTo: 'follow_request')
              .where('fromUserId', isEqualTo: widget.requesterId)
              .get();

      for (var doc in notifQuery.docs) {
        batch.delete(doc.reference);
      }

      // Create acceptance notification for the requester
      final acceptNotifRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.requesterId)
              .collection('notifications')
              .doc();

      batch.set(acceptNotifRef, {
        'type': 'follow_accepted',
        'fromUserId': widget.currentUserId,
        'timestamp': now,
        'message': 'accepted your follow request',
        'status': 'unread',
      });

      await batch.commit();

      // Only update state if widget is still mounted
      if (mounted) {
        setState(() {
          _state = RequestState.accepted;
        });
      }
    } catch (e) {
      print('Error accepting request: $e');
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to accept follow request',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _deleteRequest() async {
    if (!mounted) return;
    setState(() => _isActionLoading = true);

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Delete the follow request
      final requestRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('followRequests')
          .doc(widget.requestDocId);

      batch.delete(requestRef);

      // Remove related notification
      final notifQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUserId)
              .collection('notifications')
              .where('type', isEqualTo: 'follow_request')
              .where('fromUserId', isEqualTo: widget.requesterId)
              .get();

      for (var doc in notifQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (mounted) {}
    } catch (e) {
      print('Error deleting request: $e');
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to delete follow request',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _sendFollowBack() async {
    if (!mounted) return;
    setState(() => _isActionLoading = true);

    try {
      final now = DateTime.now();

      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Send follow request to the original requester
      // final followRequestRef = FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(widget.requesterId)
      //     .collection('followRequests')
      //     .doc(widget.currentUserId);

      // batch.set(followRequestRef, {
      //   'requesterId': widget.currentUserId,
      //   'timestamp': now,
      //   'status': 'pending',
      //   'seen': false,
      // });

      // // Create notification for the original requester
      // final notifRef =
      //     FirebaseFirestore.instance
      //         .collection('users')
      //         .doc(widget.requesterId)
      //         .collection('notifications')
      //         .doc();

      // batch.set(notifRef, {
      //   'type': 'follow_request',
      //   'fromUserId': widget.currentUserId,
      //   'timestamp': now,
      //   'message': 'sent you a follow request',
      //   'status': 'unread',
      // });

      // Add current user to requester's following (completing the mutual follow)
      final currentUserFollowingRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('following')
          .doc(widget.requesterId);

      batch.set(currentUserFollowingRef, {'timestamp': now});

      // Add requester to current user's followers
      final requesterFollowersRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.requesterId)
          .collection('followers')
          .doc(widget.currentUserId);

      batch.set(requesterFollowersRef, {'timestamp': now});

      await batch.commit();

      if (mounted) {
        setState(() {
          _state = RequestState.followBack;
        });
      }
    } catch (e) {
      print('Error sending follow back: $e');
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to send follow request',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _deleteFollowRequest(String ownerId, String otherUserId) async {
    print('Deleting follow request from $otherUserId to $ownerId');
    final followReqRef = FirebaseFirestore.instance
        .collection('users')
        .doc(ownerId)
        .collection('followRequests')
        .doc(otherUserId);

    final doc = await followReqRef.get();
    if (doc.exists) {
      await doc.reference.delete();
    }
  }

  String _getTimeAgo() {
    final now = DateTime.now();
    final requestTime = widget.timestamp.toDate();
    final difference = now.difference(requestTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildActionButtons() {
    // Show loading while data is being fetched or action is in progress
    if (_isDataLoading || _state == RequestState.loading || _isActionLoading) {
      return SizedBox(
        width: 24.w,
        height: 24.w,
        child: const CircularProgressIndicator(
          color: Colors.purple,
          strokeWidth: 2,
        ),
      );
    }

    switch (_state) {
      case RequestState.pending:
        return Row(
          children: [
            // Accept Button
            GestureDetector(
              onTap: _acceptRequest,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Accept',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // Delete Button
            GestureDetector(
              onTap: _deleteRequest,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );

      case RequestState.accepted:
        return GestureDetector(
          onTap: () async {
            await _sendFollowBack();
            _deleteFollowRequest(widget.currentUserId, widget.requesterId);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'Follow Back',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );

      case RequestState.followBack:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.green.shade700,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, color: Colors.white, size: 14.w),
              SizedBox(width: 4.w),
              Text(
                'Following',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading container while data is being loaded
    if (_isDataLoading || _requesterData == null) {
      return Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            // Profile placeholder
            Container(
              width: 54.w,
              height: 54.w,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.grey),
            ),
            SizedBox(width: 12.w),
            // Text placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16.h,
                    width: 120.w,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    height: 14.h,
                    width: 100.w,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    height: 12.h,
                    width: 60.w,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            // Loading indicator
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: const CircularProgressIndicator(
                color: Colors.purple,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      child: Row(
        children: [
          // Profile Image
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.pinkAccent],
              ),
            ),
            padding: EdgeInsets.all(2.w),
            child: CircleAvatar(
              radius: 25.r,
              backgroundColor: Colors.transparent,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl:
                      _requesterData!['profileImageUrl'] ??
                      'https://i.stack.imgur.com/l60Hf.png',
                  width: 50.w,
                  height: 50.w,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey.shade800,
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.grey.shade800,
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                ),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _requesterData!['name'] ?? 'Unknown User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'wants to follow you',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _getTimeAgo(),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 12.w),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }
}
