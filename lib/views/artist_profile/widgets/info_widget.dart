import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/notifications/fcm_notification_sender.dart';
import 'package:banger_drop/views/artist_profile/controller/artist_profile_controller.dart';
import 'package:banger_drop/views/chat/chat_view.dart';
import 'package:banger_drop/views/settings/settings_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/get_core.dart';

class ProfileInfoWidget extends StatefulWidget {
  final String imgUrl;
  final String name;
  final int points;
  final int followers;
  final int following;
  final bool showSetting;
  final bool isFollowing;
  final VoidCallback? onFollowToggle; // 👈 callback
  final VoidCallback? onFollowersTap; // 👈 callback
  final VoidCallback? onFollowingTap; // 👈 callback
  final showFollowButton;
  final bool hasRequested; // ✅ NEW
  final uid;

  const ProfileInfoWidget({
    super.key,
    required this.imgUrl,
    required this.name,
    required this.points,
    required this.followers,
    required this.following,
    this.showSetting = false,
    this.isFollowing = false,
    this.onFollowToggle,
    this.onFollowersTap,
    this.onFollowingTap,
    required this.showFollowButton,
    required this.hasRequested,
    required this.uid,
  });

  @override
  State<ProfileInfoWidget> createState() => _ProfileInfoWidgetState();
}

class _ProfileInfoWidgetState extends State<ProfileInfoWidget> {
  String getRank(int pts) {
    if (pts < 1000) return 'Novice';
    if (pts < 5000) return 'Apprentice';
    if (pts < 10000) return 'Enthusiast';
    if (pts < 20000) return 'Advisor';
    if (pts < 50000) return 'Human orchestra';
    if (pts < 100000) return 'Passionate';
    if (pts < 250000) return 'Expert';
    if (pts < 500000) return 'Minister of sound';
    if (pts < 1000000) return 'Emperor';
    return 'Godlike';
  }

  bool isBlocked = false;

  @override
  void initState() {
    super.initState();
    checkIfBlocked();
  }

  Future<void> checkIfBlocked() async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .get();

    if (userDoc.exists) {
      final blockedList = List.from(userDoc.data()?['blocked'] ?? []);
      setState(() {
        isBlocked = blockedList.contains(widget.uid);
      });
    }
  }

  Future<void> toggleBlockStatus() async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final currentUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid);
    final otherUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid);

    if (isBlocked) {
      // UNBLOCK
      await currentUserRef.set({
        'blocked': FieldValue.arrayRemove([widget.uid]),
      }, SetOptions(merge: true));

      setState(() {
        isBlocked = false;
      });

      Get.snackbar(
        'Unblocked',
        'User has been unblocked',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      // BLOCK

      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Add to blocked list
      batch.set(currentUserRef, {
        'blocked': FieldValue.arrayUnion([widget.uid]),
      }, SetOptions(merge: true));

      // Remove widget.uid from current user's 'following' and 'followers'
      final currentUserFollowingRef = currentUserRef
          .collection('following')
          .doc(widget.uid);
      final currentUserFollowersRef = currentUserRef
          .collection('followers')
          .doc(widget.uid);

      batch.delete(currentUserFollowingRef);
      batch.delete(currentUserFollowersRef);

      // Remove current user from other user's 'following' and 'followers'
      final otherUserFollowingRef = otherUserRef
          .collection('following')
          .doc(currentUid);
      final otherUserFollowersRef = otherUserRef
          .collection('followers')
          .doc(currentUid);

      batch.delete(otherUserFollowingRef);
      batch.delete(otherUserFollowersRef);

      await batch.commit();

      setState(() {
        isBlocked = true;
      });
      Get.back();
      Get.snackbar(
        'Blocked',
        'User has been blocked',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rank = getRank(widget.points);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showFollowButton)
            GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
              ),
            ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        fontSize: 25.sp,
                        fontWeight: FontWeight.bold,
                        foreground:
                            Paint()
                              ..shader = const LinearGradient(
                                colors: [
                                  Colors.deepPurple,
                                  Colors.pink,
                                  Colors.purple,
                                ],
                              ).createShader(
                                const Rect.fromLTWH(0, 0, 200, 70),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$rank - ${widget.points} Points',
                      style: appThemes.Medium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            widget.onFollowersTap!();
                          },
                          child: Text(
                            '${widget.followers} Followers -',
                            style: appThemes.small,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            widget.onFollowingTap!();
                          },
                          child: Text(
                            ' ${widget.following} Followed',
                            style: appThemes.small,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.showFollowButton)
                      Row(
                        children: [
                          if (!isBlocked)
                            FollowButton(
                              currentUserId:
                                  FirebaseAuth.instance.currentUser!.uid,
                              targetUserId: widget.uid,
                            ),
                          // ElevatedButton(
                          //   onPressed: widget.onFollowToggle,
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor:
                          //         widget.isFollowing
                          //             ? Colors.grey[800]
                          //             : widget.hasRequested
                          //             ? Colors.grey[600]
                          //             : Colors.pinkAccent,

                          //     padding: const EdgeInsets.symmetric(
                          //       horizontal: 20,
                          //       vertical: 10,
                          //     ),
                          //     shape: RoundedRectangleBorder(
                          //       borderRadius: BorderRadius.circular(8),
                          //     ),
                          //   ),
                          //   child: Text(
                          //     widget.isFollowing
                          //         ? 'Unfollow'
                          //         : widget.hasRequested
                          //         ? 'Requested'
                          //         : 'Follow',
                          //     style: const TextStyle(color: Colors.white),
                          //   ),
                          // ),
                          IconButton(
                            onPressed: () async {
                              final userDoc =
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(widget.uid)
                                      .get();

                              if (userDoc.exists &&
                                  userDoc.data()?['Deactivated'] == true) {
                                // Show dialog if account is deactivated
                                Get.defaultDialog(
                                  title: 'Account Deactivated',
                                  middleText:
                                      'This user account is deactivated.',
                                  confirm: ElevatedButton(
                                    onPressed: () => Get.back(),
                                    child: Text('OK'),
                                  ),
                                );
                              } else {
                                // Navigate to chat screen
                                Get.to(
                                  () => ChatScreen(
                                    userId: widget.uid,
                                    name: widget.name,
                                    imgUrl:
                                        widget.imgUrl ??
                                        'https://i.stack.imgur.com/l60Hf.png',
                                  ),
                                );
                              }
                            },

                            icon: Image.asset(
                              'assets/images/message.png',
                              width: 25.w,
                              height: 25.h,
                            ),
                          ),
                          IconButton(
                            onPressed: toggleBlockStatus,
                            icon: Icon(
                              isBlocked ? Icons.lock_open_sharp : Icons.block,
                              color:
                                  isBlocked
                                      ? appColors.purple
                                      : appColors.purple,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 0),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.purple, Colors.pinkAccent],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Colors.purple, Colors.pinkAccent],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 40.r,
                        backgroundColor: Colors.transparent,
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: widget.imgUrl,
                            width: 80.r,
                            height: 80.r,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) =>
                                    const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                            errorWidget:
                                (context, url, error) => const Icon(
                                  Icons.person,
                                  color: Colors.black,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.showSetting)
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () => Get.to(() => const SettingsScreen()),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//////
///
// Enhanced Follow Button with better context and user feedback

// Enum to track follow button states
// Enhanced Follow Button with better context and user feedback

// Enum to track follow button states
enum FollowState { follow, requested, followed, followBack, unfollow }

// The enhanced follow button widget
class FollowButton extends StatefulWidget {
  final String currentUserId;
  final String targetUserId;
  final String? targetUserName; // Added for better context

  const FollowButton({
    required this.currentUserId,
    required this.targetUserId,
    this.targetUserName,
    super.key,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  FollowState _followState = FollowState.follow;
  bool _isLoading = false;
  bool _hasPendingRequest =
      false; // ✅ NEW: Track if there's a pending request to accept

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  @override
  void didUpdateWidget(covariant FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetUserId != oldWidget.targetUserId) {
      _checkFollowStatus(); // re-check if user changes
    }
  }

  Future<void> _checkFollowStatus() async {
    setState(() => _isLoading = true);

    try {
      // Check if current user is following target user
      final followingDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUserId)
              .collection('following')
              .doc(widget.targetUserId)
              .get();

      // Check if target user is following current user
      final followersDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.targetUserId)
              .collection('followers')
              .doc(widget.currentUserId)
              .get();

      // Check if current user has sent a follow request to target user
      final sentRequestDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.targetUserId)
              .collection('followRequests')
              .doc(widget.currentUserId)
              .get();

      // Check if target user has sent a follow request to current user
      final receivedRequestDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUserId)
              .collection('followRequests')
              .doc(widget.targetUserId)
              .get();

      if (followingDoc.exists && followersDoc.exists) {
        // Both are following each other - mutual follow
        setState(() => _followState = FollowState.followed);
      } else if (followingDoc.exists) {
        // Current user is following target user but not vice versa
        setState(() => _followState = FollowState.unfollow);
      } else if (receivedRequestDoc.exists) {
        // Check the status of the received request
        final requestData = receivedRequestDoc.data() as Map<String, dynamic>?;
        final requestStatus = requestData?['status'] ?? 'pending';

        if (requestStatus == 'pending') {
          // Target user has sent a pending follow request to current user - show "Accept Request"
          setState(() => _followState = FollowState.followBack);
          _hasPendingRequest = true;
        } else {
          // Request was already accepted/declined, check actual follow relationship
          final targetFollowingCurrentDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.targetUserId)
                  .collection('following')
                  .doc(widget.currentUserId)
                  .get();

          if (targetFollowingCurrentDoc.exists) {
            // Target user is following current user, show "Follow Back"
            setState(() => _followState = FollowState.followBack);
            _hasPendingRequest = false;
          } else {
            // ✅ FIXED: Check for sent request before defaulting to follow
            if (sentRequestDoc.exists) {
              setState(() => _followState = FollowState.requested);
            } else {
              setState(() => _followState = FollowState.follow);
            }
          }
        }
      } else {
        // Check if target user is already following current user (for follow back scenario)
        final targetFollowingCurrentDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.targetUserId)
                .collection('following')
                .doc(widget.currentUserId)
                .get();

        if (targetFollowingCurrentDoc.exists) {
          // Target user is following current user, show "Follow Back"
          setState(() => _followState = FollowState.followBack);
          _hasPendingRequest = false;
        } else {
          // ✅ FIXED: Check for sent request before defaulting to follow
          if (sentRequestDoc.exists) {
            setState(() => _followState = FollowState.requested);
          } else {
            setState(() => _followState = FollowState.follow);
          }
        }
      }
    } catch (e) {
      print('Error checking follow status: $e');
      setState(() => _followState = FollowState.follow);
    } finally {
      setState(() => _isLoading = false);
    }
  }

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

  Future<void> _deleteFollowRequest(String ownerId, String otherUserId) async {
    print('deleting follow request from $otherUserId to $ownerId');
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

  Future<void> _sendFollowRequest() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();

      // Send follow request
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.targetUserId)
          .collection('followRequests')
          .doc(widget.currentUserId)
          .set({
            'requesterId': widget.currentUserId,
            'timestamp': now,
            'status': 'pending',
            'followRequests': AppConstants.userImg,
          });

      // Create notification
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.targetUserId)
          .collection('notifications')
          .add({
            'type': 'follow_request',
            'fromUserId': widget.currentUserId,
            'timestamp': now,
            'message': 'sent you a follow request',
            'status': 'unread',
          });
      print('sending notification');
      if (await fetchNotificationPreference('followUp', widget.targetUserId)) {
        final targetToken = await sender.fetchFcmTokensForUser(
          widget.targetUserId,
        );
        // ✅ Call notification after transaction
        if (widget.currentUserId != widget.targetUserId) {
          for (String token in targetToken) {
            await sender.sendNotification(
              title: "Follow Request",
              body: "${AppConstants.userName} wants to follow you",
              targetToken: token,
              dataPayload: {"type": "follow_request"},
              uid: widget.targetUserId,
            );
          }
        }
      }

      setState(() => _followState = FollowState.requested);
    } catch (e) {
      print('Error sending follow request: $e');
      Get.snackbar(
        'Error',
        'Failed to send follow request',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelFollowRequest() async {
    setState(() => _isLoading = true);

    try {
      // Delete follow request
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.targetUserId)
          .collection('followRequests')
          .doc(widget.currentUserId)
          .delete();

      // Delete related notifications
      final notifQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.targetUserId)
              .collection('notifications')
              .where('type', isEqualTo: 'follow_request')
              .where('fromUserId', isEqualTo: widget.currentUserId)
              .get();

      for (var doc in notifQuery.docs) {
        await doc.reference.delete();
      }

      setState(() => _followState = FollowState.follow);
    } catch (e) {
      print('Error cancelling follow request: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptFollowRequest() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();

      // ✅ FIXED: Create proper following relationship
      // Target user (who sent request) follows current user (who is accepting)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.targetUserId)
          .collection('following')
          .doc(widget.currentUserId)
          .set({'timestamp': now});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('followers')
          .doc(widget.targetUserId)
          .set({'timestamp': now});

      // ✅ FIX: DELETE the follow request document instead of updating status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('followRequests')
          .doc(widget.targetUserId)
          .update({
            'status': 'accepted',
          }); // Changed from .update() to .delete()

      // Optional: Create acceptance notification for the requester
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.targetUserId)
          .collection('notifications')
          .add({
            'type': 'follow_accepted',
            'fromUserId': widget.currentUserId,
            'timestamp': now,
            'message': 'accepted your follow request',
            'status': 'unread',
          });

      // ✅ FIXED: After accepting request, show "Follow Back" button
      // Since target user is now following current user, current user can follow back
      setState(() {
        _followState = FollowState.followBack;
        _hasPendingRequest = false; // No more pending request
      });
    } catch (e) {
      print('Error accepting follow request: $e');
      Get.snackbar(
        'Error',
        'Failed to accept follow request',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _followBackUser() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();

      // Create following relationship (current user follows target user)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('following')
          .doc(widget.targetUserId)
          .set({'timestamp': now});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.targetUserId)
          .collection('followers')
          .doc(widget.currentUserId)
          .set({'timestamp': now});

      // Create notification for target user

      // Check if this creates a mutual follow relationship
      final targetFollowingCurrentDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.targetUserId)
              .collection('following')
              .doc(widget.currentUserId)
              .get();

      if (targetFollowingCurrentDoc.exists) {
        // Both are following each other - show "Following"
        setState(() => _followState = FollowState.followed);
      } else {
        // Only current user is following target user - show "Following" (unfollow state)
        setState(() => _followState = FollowState.unfollow);
      }

      // Get.snackbar(
      //   'Success',
      //   'You are now following ${widget.targetUserName ?? "this user"}',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.green.withOpacity(0.8),
      //   colorText: Colors.white,
      // );
      _deleteFollowRequest(widget.currentUserId, widget.targetUserId);
    } catch (e) {
      print('Error following back: $e');
      Get.snackbar(
        'Error',
        'Failed to follow user',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unfollowUser() async {
    setState(() => _isLoading = true);

    try {
      // Remove following relationship (current user unfollowing target user)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('following')
          .doc(widget.targetUserId)
          .delete();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.targetUserId)
          .collection('followers')
          .doc(widget.currentUserId)
          .delete();

      // Check if target user is still following current user
      final targetFollowingDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.targetUserId)
              .collection('following')
              .doc(widget.currentUserId)
              .get();

      if (targetFollowingDoc.exists) {
        // Target user is still following current user, show "Follow Back"
        setState(() => _followState = FollowState.followBack);
      } else {
        // No relationship exists, show "Follow"
        setState(() => _followState = FollowState.follow);
      }
    } catch (e) {
      print('Error unfollowing user: $e');
      Get.snackbar(
        'Error',
        'Failed to unfollow user',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleTap() {
    if (_isLoading) return;

    switch (_followState) {
      case FollowState.follow:
        _sendFollowRequest();
        break;
      case FollowState.requested:
        _showCancelRequestDialog();
        break;
      case FollowState.followed:
        _showUnfollowDialog();
        break;
      case FollowState.followBack:
        // ✅ FIXED: Check if this is accepting a request or following back
        _checkAndHandleFollowBack();
        break;
      case FollowState.unfollow:
        _showUnfollowDialog();
        break;
    }
  }

  // ✅ NEW: Check if there's a pending request to accept or just follow back

  Future<void> _checkAndHandleFollowBack() async {
    try {
      // Check if there's a pending request from target user
      final receivedRequestDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUserId)
              .collection('followRequests')
              .doc(widget.targetUserId)
              .get();

      if (receivedRequestDoc.exists) {
        final requestData = receivedRequestDoc.data() as Map<String, dynamic>?;
        final requestStatus = requestData?['status'] ?? 'pending';

        if (requestStatus == 'pending') {
          // There's a pending request, accept it first then follow back
          await _acceptFollowRequest();
          return;
        }
      }

      // No pending request, just follow back directly
      _followBackUser();
    } catch (e) {
      print('Error checking follow back: $e');
      // Fallback to direct follow back
      _followBackUser();
    }
  }

  void _showCancelRequestDialog() {
    Get.defaultDialog(
      title: 'Cancel Request?',
      middleText: 'Are you sure you want to cancel your follow request?',
      textCancel: 'No',
      textConfirm: 'Yes, Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        _cancelFollowRequest();
      },
    );
  }

  void _showUnfollowDialog() {
    Get.defaultDialog(
      title: 'Unfollow?',
      middleText:
          'Are you sure you want to unfollow ${widget.targetUserName ?? "this user"}?',
      textCancel: 'No',
      textConfirm: 'Yes, Unfollow',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        _unfollowUser();
      },
    );
  }

  // Show confirmation dialog for accepting follow request
  void _showAcceptRequestDialog() {
    Get.defaultDialog(
      title: 'Accept Follow Request?',
      middleText:
          'Accept follow request from ${widget.targetUserName ?? "this user"}?',
      textCancel: 'Decline',
      textConfirm: 'Accept',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        _acceptFollowRequest();
      },
      onCancel: () {
        Get.back();
        _declineFollowRequest();
      },
    );
  }

  // Method to decline follow request
  Future<void> _declineFollowRequest() async {
    setState(() => _isLoading = true);

    try {
      // Remove the follow request
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('followRequests')
          .doc(widget.targetUserId)
          .delete();

      // ✅ FIXED: Update notification to declined (DON'T delete)
      final notifQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUserId)
              .collection('notifications')
              .where('type', isEqualTo: 'follow_request')
              .where('fromUserId', isEqualTo: widget.targetUserId)
              .get();

      for (var doc in notifQuery.docs) {
        await doc.reference.update({
          'type': 'follow_request_declined',
          'message': 'You declined their follow request',
          'status': 'read',
          'declinedAt': DateTime.now(),
        });
      }

      setState(() => _followState = FollowState.follow);
    } catch (e) {
      print('Error declining follow request: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String buttonText;
    Color backgroundColor;
    Color textColor = Colors.white;
    IconData? icon;

    switch (_followState) {
      case FollowState.follow:
        buttonText = 'Follow';
        backgroundColor = Colors.pink;
        icon = Icons.person_add;
        break;
      case FollowState.requested:
        buttonText = 'Requested';
        backgroundColor = Colors.grey.shade600;
        icon = Icons.access_time;
        break;
      case FollowState.followed:
        buttonText = 'Following';
        backgroundColor = Colors.green;
        icon = Icons.check;
        break;
      case FollowState.followBack:
        // ✅ FIXED: Show different text based on whether there's a pending request
        if (_hasPendingRequest) {
          buttonText = 'Accept Request';
          backgroundColor = Colors.purple;
          icon = Icons.how_to_reg;
        } else {
          buttonText = 'Follow Back';
          backgroundColor = Colors.purple;
          icon = Icons.person_add;
        }
        break;
      case FollowState.unfollow:
        buttonText = 'Following';
        backgroundColor = Colors.green;
        icon = Icons.check;
        break;
    }

    return Container(
      height: 40,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          disabledBackgroundColor: backgroundColor.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          elevation: 2,
        ),
        child:
            _isLoading
                ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16),
                      SizedBox(width: 4),
                    ],
                    Text(
                      buttonText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
