// controller/artist_profile_controller.dart
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileViewController extends GetxController {
  final String userId;

  ProfileViewController(this.userId);

  final isLoading = true.obs;
  final userData = Rxn<Map<String, dynamic>>();
  final playlists = <DocumentSnapshot>[].obs;
  final bangers = <DocumentSnapshot>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> _cleanUpInvalidFollowersAndFollowing() async {
    final userRef = _firestore.collection('users');

    // Clean up followers
    final followersSnapshot =
        await userRef.doc(userId).collection('followers').get();
    for (var doc in followersSnapshot.docs) {
      final followerId = doc.id;
      final userExists = await userRef
          .doc(followerId)
          .get()
          .then((d) => d.exists);
      if (!userExists) {
        await userRef
            .doc(userId)
            .collection('followers')
            .doc(followerId)
            .delete();
        debugPrint('Deleted invalid follower: $followerId');
      }
    }

    // Clean up following
    final followingSnapshot =
        await userRef.doc(userId).collection('following').get();
    for (var doc in followingSnapshot.docs) {
      final followingId = doc.id;
      final userExists = await userRef
          .doc(followingId)
          .get()
          .then((d) => d.exists);
      if (!userExists) {
        await userRef
            .doc(userId)
            .collection('following')
            .doc(followingId)
            .delete();
        debugPrint('Deleted invalid following: $followingId');
      }
    }
  }

  Future<void> fetchData() async {
    try {
      isLoading.value = true;

      final userSnap = await _firestore.collection('users').doc(userId).get();

      final playlistSnap =
          await _firestore
              .collection('Playlist')
              .where('created By', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      final bangersSnap =
          await _firestore
              .collection('Bangers')
              .where('CreatedBy', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      userData.value = userSnap.data();
      playlists.assignAll(playlistSnap.docs);
      bangers.assignAll(bangersSnap.docs);
      await _cleanUpInvalidFollowersAndFollowing(); // 🧹 Clean up on load
    } finally {
      isLoading.value = false;
    }
  }

  void showDeleteDialog(BuildContext context, String bangerId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Delete Post"),
            content: Text("Are you sure you want to delete this banger?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop(); // close dialog
                  await deleteBanger(bangerId);
                },
                child: Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Future<void> deleteBanger(String bangerId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Bangers')
          .doc(bangerId)
          .delete();
      fetchData();
      Get.snackbar(
        "Deleted",
        "Banger deleted Successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to delete: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void showDeletePlaylistDialog(BuildContext context, String playlistId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Delete Playlist"),
            content: Text("Are you sure you want to delete this playlist?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop(); // Close dialog
                  await deletePlaylist(playlistId);
                },
                child: Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Playlist')
          .doc(playlistId)
          .delete();

      Get.snackbar(
        "Deleted",
        "Playlist has been successfully deleted.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Optional: go back if viewing deleted playlist
      Get.back();
      fetchData();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to delete playlist: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxBool isFollowing = false.obs;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Call this on init
  Future<void> checkIfFollowing(String profileUserId) async {
    final doc =
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('following')
            .doc(profileUserId)
            .get();

    isFollowing.value = doc.exists;
  }

  /// Follow / Unfollow Toggle
  Future<void> toggleFollow(String profileUserId) async {
    final followingRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(profileUserId);

    final followerRef = _firestore
        .collection('users')
        .doc(profileUserId)
        .collection('followers')
        .doc(currentUserId);

    final isCurrentlyFollowing = isFollowing.value;

    try {
      if (isCurrentlyFollowing) {
        // 🔽 Unfollow
        await followingRef.delete();
        await followerRef.delete();
        isFollowing.value = false;
      } else {
        // 🔼 Follow
        final now = Timestamp.now();
        await followingRef.set({'timestamp': now});
        await followerRef.set({'timestamp': now});
        isFollowing.value = true;
      }
    } catch (e) {
      print("Follow toggle error: $e");
    }
  }

  RxInt followersCount = 0.obs;
  RxInt followingCount = 0.obs;

  StreamSubscription? _followersSub;
  StreamSubscription? _followingSub;

  void listenToFollowCounts(String uid) {
    _followersSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('followers')
        .snapshots()
        .listen((snapshot) {
          followersCount.value = snapshot.size;
        });

    _followingSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('following')
        .snapshots()
        .listen((snapshot) {
          followingCount.value = snapshot.size;
        });
  }

  @override
  void onClose() {
    _followersSub?.cancel();
    _followingSub?.cancel();
    super.onClose();
  }

  void showFollowersDialog(String userId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Followers'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: getFollowersWithDetails(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No followers');
              }

              final followers = snapshot.data!;

              return ListView.builder(
                shrinkWrap: true,
                itemCount: followers.length,
                itemBuilder: (context, index) {
                  final follower = followers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: follower['img'],
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
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

                    title: Text(follower['name']),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () async {
                        await removeFollower(userId, follower['uid']);
                        Get.back();
                        showFollowersDialog(userId); // Refresh dialog
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getFollowersWithDetails(String uid) async {
    final followerSnapshots =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('followers')
            .get();

    final List<String> followerIds =
        followerSnapshots.docs.map((doc) => doc.id).toList();

    if (followerIds.isEmpty) return [];

    final userSnapshots =
        await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: followerIds)
            .get();

    return userSnapshots.docs.map((doc) {
      final data = doc.data();
      return {
        'uid': doc.id,
        'name': data['name'] ?? '',
        'img': data['img'] ?? '',
      };
    }).toList();
  }

  void showFollowingDialog(String userId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Following'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: getFollowingWithDetails(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('Not following anyone');
              }

              final following = snapshot.data!;

              return ListView.builder(
                shrinkWrap: true,
                itemCount: following.length,
                itemBuilder: (context, index) {
                  final user = following[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: user['img'],
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
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
                    title: Text(user['name']),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () async {
                        await unfollowUser(userId, user['uid']);
                        Get.back();
                        showFollowingDialog(userId); // Refresh dialog
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getFollowingWithDetails(String uid) async {
    final followingSnapshots =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('following')
            .get();

    final List<String> followingIds =
        followingSnapshots.docs.map((doc) => doc.id).toList();

    if (followingIds.isEmpty) return [];

    final userSnapshots =
        await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: followingIds)
            .get();

    return userSnapshots.docs.map((doc) {
      final data = doc.data();
      return {
        'uid': doc.id,
        'name': data['name'] ?? '',
        'img': data['img'] ?? '',
      };
    }).toList();
  }

  Future<void> removeFollower(String myId, String followerId) async {
    final firestore = FirebaseFirestore.instance;

    final followerRef = firestore.collection('users').doc(followerId);
    final myRef = firestore.collection('users').doc(myId);

    // Step 1: Remove from following and followers
    await followerRef.collection('following').doc(myId).delete();
    await myRef.collection('followers').doc(followerId).delete();

    // Step 2: Remove follow notifications from both users
    await _deleteFollowNotification(myId, followerId); // from myId
    await _deleteFollowNotification(followerId, myId); // from followerId

    // Step 3: Remove followRequests from both users
    await _deleteFollowRequest(myId, followerId); // from myId
    await _deleteFollowRequest(followerId, myId); // from followerId
  }

  Future<void> _deleteFollowNotification(
    String ownerId,
    String otherUserId,
  ) async {
    final notificationsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(ownerId)
        .collection('notifications');

    final querySnapshot =
        await notificationsRef
            .where('type', isEqualTo: 'follow')
            .where('fromUserId', isEqualTo: otherUserId)
            .get();

    for (final doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _deleteFollowRequest(String ownerId, String otherUserId) async {
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

  Future<void> unfollowUser(String myId, String followingId) async {
    final firestore = FirebaseFirestore.instance;

    final myRef = firestore.collection('users').doc(myId);
    final followingRef = firestore.collection('users').doc(followingId);

    // Step 1: Remove from following and followers
    await myRef.collection('following').doc(followingId).delete();
    await followingRef.collection('followers').doc(myId).delete();

    // Step 2: Delete follow notification sent to followingId
    await _deleteFollowNotification(
      followingId,
      myId,
    ); // from their notifications

    // Step 3: Delete followRequests (if any) between both users
    await _deleteFollowRequest(myId, followingId);
    await _deleteFollowRequest(followingId, myId);
  }
}
