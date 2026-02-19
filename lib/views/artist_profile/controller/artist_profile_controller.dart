import 'dart:async';
import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/notifications/fcm_notification_sender.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ArtistProfileController extends GetxController {
  final String userId;
  ArtistProfileController(this.userId);

  final isLoading = true.obs;
  final userData = Rxn<Map<String, dynamic>>();
  final playlists = <DocumentSnapshot>[].obs;
  final bangers = <DocumentSnapshot>[].obs;

  final isPrivate = false.obs;
  final isFriend = false.obs;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxBool isFollowing = false.obs;
  RxBool hasRequested = false.obs;

  String get currentUserId => _auth.currentUser?.uid ?? '';
  final hasYouTubeLink = false.obs;
  final hasSpotifyLink = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkIfBlockedByOther(userId); // <-- add this

    fetchData();
    fetchSocialData();
    checkIfFollowing(userId);
    checkIfRequested(userId);
  }

  Future<void> fetchData() async {
    isLoading.value = true;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      final data = doc.data();
      userData.value = data;
      await cleanUpInvalidFollowersAndFollowing(userId);

      // Check restricted profile
      final bool isRestricted = data?['restrictedProfile'] == true;

      if (!isRestricted) {
        isPrivate.value = false;
      } else {
        final followerDoc =
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('followers')
                .doc(currentUserId)
                .get();

        isPrivate.value = !followerDoc.exists;
      }

      final youtubeLink = data?['youtube'] as String?;
      final spotifyLink = data?['spotify'] as String?;

      hasYouTubeLink.value = (youtubeLink ?? '').trim().isNotEmpty;
      hasSpotifyLink.value = (spotifyLink ?? '').trim().isNotEmpty;
      print("YouTube link: $youtubeLink");
      print("Spotify link: $spotifyLink");
      print("YouTube flag: ${hasYouTubeLink.value}");
      print("Spotify flag: ${hasSpotifyLink.value}");
    } catch (e) {
      print("Error fetching user data: $e");
      isPrivate.value = false;
      hasYouTubeLink.value = false;
      hasSpotifyLink.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSocialData() async {
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
    } finally {
      isLoading.value = false;
    }
  }

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

  Future<void> checkIfRequested(String profileUserId) async {
    final query =
        await _firestore
            .collection('notifications')
            .where('type', isEqualTo: 'follow_request')
            .where('bangerOwnerId', isEqualTo: profileUserId)
            .where('status', isEqualTo: 'pending')
            .get();

    hasRequested.value = query.docs.any((doc) {
      final users = List<Map<String, dynamic>>.from(doc['users']);
      return users.any((u) => u['uid'] == currentUserId);
    });
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

  Future<void> _removeExistingFollowRequest(String profileUserId) async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('notifications')
            .where('bangerOwnerId', isEqualTo: profileUserId)
            .where('type', isEqualTo: 'follow_request')
            .get();

    for (final doc in querySnapshot.docs) {
      final users = List<Map<String, dynamic>>.from(doc['users']);
      final updatedUsers =
          users.where((u) => u['uid'] != currentUserId).toList();

      if (updatedUsers.length != users.length) {
        if (updatedUsers.isEmpty) {
          await doc.reference.delete();
        } else {
          await doc.reference.update({'users': updatedUsers});
        }
      }
    }

    hasRequested.value = false;
  }

  Future<void> addNotification2({
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

    // Step 1: Delete existing 'follow' notification for the same banger
    final followQuery =
        await firestore
            .collection('notifications')
            .where('bangerId', isEqualTo: bangerId)
            .where('bangerOwnerId', isEqualTo: bangerOwnerId)
            .where('type', isEqualTo: 'follow')
            .get();

    for (final doc in followQuery.docs) {
      await doc.reference.delete();
    }

    // Step 2: Continue with regular notification logic
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
      "img": userImg, // ✅ Profile image
    };

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final users = List<Map<String, dynamic>>.from(doc['users']);

      // Avoid duplicate user entry
      if (!users.any((u) => u['uid'] == userId)) {
        users.add(userMap);
        await doc.reference.update({
          "users": users,
          "timestamp": Timestamp.now(),
        });
      }
    } else {
      // Create new notification
      await firestore.collection('notifications').add({
        "bangerId": bangerId,
        "bangerOwnerId": bangerOwnerId,
        "type": actionType,
        "users": [userMap],
        "bangerImg": bangerImg, // ✅ Banger image
        "timestamp": Timestamp.now(),
        "seenBy": [],
      });
    }
  }

  Future<void> sendFollowRequestToggle(String profileUserId) async {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final followersRef = _firestore
        .collection('users')
        .doc(profileUserId)
        .collection('followers')
        .doc(currentUserId);

    final followingRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(profileUserId);

    final isFollowingSnapshot = await followersRef.get();
    final isFollowingAlready = isFollowingSnapshot.exists;

    final youAreFollowed =
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('followers')
            .doc(profileUserId)
            .get();

    final theyFollowYou = youAreFollowed.exists;

    // UNFOLLOW logic
    if (isFollowingAlready) {
      await followersRef.delete();
      await followingRef.delete();
      await _removeExistingFollowRequest(profileUserId);

      hasRequested.value = false;
      isFollowing.value = false;
      return;
    }

    // 🔁 FOLLOW BACK: if they already follow you, auto-create the relationship
    if (theyFollowYou) {
      final now = Timestamp.now();

      await followersRef.set({"timestamp": now});
      await followingRef.set({"timestamp": now});

      // Clean up any existing follow request
      await _removeExistingFollowRequest(profileUserId);

      hasRequested.value = false;
      isFollowing.value = true;
      await addNotification2(
        userImg: AppConstants.userImg,
        bangerImg: '',
        bangerId: AppConstants.userId,
        bangerOwnerId: userId,
        actionType: 'follow',
        userId: AppConstants.userId,
        userName: AppConstants.userName,
      );
      if (await fetchNotificationPreference('followUp', profileUserId)) {
        final targetTokens = await sender.fetchFcmTokensForUser(profileUserId);

        for (String token in targetTokens) {
          await sender.sendNotification(
            title: "New Follower",
            body: "${AppConstants.userName} started following you",
            targetToken: token,
            dataPayload: {"type": "social"},
            uid: profileUserId,
          );
        }
      }
      return;
    }

    // 🚫 Avoid sending duplicate requests
    final existingFollowRequest =
        await _firestore
            .collection('notifications')
            .where('bangerOwnerId', isEqualTo: profileUserId)
            .where('type', isEqualTo: 'follow_request')
            .where('status', isEqualTo: 'pending')
            .get();

    bool requestAlreadySent = false;

    for (var doc in existingFollowRequest.docs) {
      final users = List<Map<String, dynamic>>.from(doc['users']);
      if (users.any((u) => u['uid'] == currentUserId)) {
        requestAlreadySent = true;
        break;
      }
    }

    if (requestAlreadySent) {
      await _removeExistingFollowRequest(profileUserId);
      return;
    }

    // ✅ Otherwise, send a follow request
    hasRequested.value = true;

    await addNotification(
      bangerId: "",
      bangerOwnerId: profileUserId,
      actionType: "follow_request",
      userId: currentUserId,
      userName: AppConstants.userName,
      userImg: AppConstants.userImg,
      bangerImg: "",
    );

    // ✅ Respect notification preferences
    if (await fetchNotificationPreference('followUp', profileUserId)) {
      final targetTokens = await sender.fetchFcmTokensForUser(profileUserId);

      for (String token in targetTokens) {
        await sender.sendNotification(
          title: "Follow Request",
          body: "${AppConstants.userName} wants to follow you",
          targetToken: token,
          dataPayload: {"type": "social"},
          uid: profileUserId,
        );
      }
    }
  }

  Future<void> acceptFollowRequest(
    String requesterUid,
    String notificationId,
  ) async {
    final now = Timestamp.now();

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('followers')
        .doc(requesterUid)
        .set({"timestamp": now});
    await _firestore
        .collection('users')
        .doc(requesterUid)
        .collection('following')
        .doc(currentUserId)
        .set({"timestamp": now});

    await _firestore.collection('notifications').doc(notificationId).update({
      "status": "accepted",
    });
    checkIfFollowing(requesterUid);
  }

  Future<void> addNotification({
    required String bangerId,
    required String bangerOwnerId,
    required String actionType,
    required String userId,
    required String userName,
    required String userImg,
    required String bangerImg,
  }) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final query =
        await _firestore
            .collection('notifications')
            .where('bangerId', isEqualTo: bangerId)
            .where('bangerOwnerId', isEqualTo: bangerOwnerId)
            .where('type', isEqualTo: actionType)
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
            )
            .get();

    final userMap = {"uid": userId, "name": userName, "img": userImg};

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final users = List<Map<String, dynamic>>.from(doc['users']);
      if (!users.any((u) => u['uid'] == userId)) {
        users.add(userMap);
        await doc.reference.update({
          "users": users,
          "timestamp": Timestamp.now(),
        });
      }
    } else {
      await _firestore.collection('notifications').add({
        "bangerId": bangerId,
        "bangerOwnerId": bangerOwnerId,
        "type": actionType,
        "users": [userMap],
        "bangerImg": bangerImg,
        "timestamp": Timestamp.now(),
        "status": actionType == 'follow_request' ? 'pending' : null,
        "seenBy": [],
      });
    }
  }

  // FOLLOW COUNTS
  RxInt followersCount = 0.obs;
  RxInt followingCount = 0.obs;
  StreamSubscription? _followersSub;
  StreamSubscription? _followingSub;

  void listenToFollowCounts(String uid) {
    _followersSub = _firestore
        .collection('users')
        .doc(uid)
        .collection('followers')
        .snapshots()
        .listen((snapshot) {
          followersCount.value = snapshot.size;
        });

    _followingSub = _firestore
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

  Future<void> showFollowersDialog(String userId) async {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: getFollowersWithDetails(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 150,
                child: Center(child: Text('No followers found')),
              );
            }

            final followers = snapshot.data!;

            return SizedBox(
              height: 400,
              width: 300,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Followers',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: followers.length,
                      itemBuilder: (context, index) {
                        final follower = followers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[300],
                            radius: 20, // optional: adjust size as needed
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: follower['img'] ?? '',
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

                          title: Text(follower['name'] ?? 'Unknown'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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

  Future<void> showFollowingDialog(String userId) async {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: getFollowingWithDetails(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 150,
                child: Center(child: Text('No following Users found')),
              );
            }

            final following = snapshot.data!;

            return SizedBox(
              height: 400,
              width: 300,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Following',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: following.length,
                      itemBuilder: (context, index) {
                        final user = following[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[300],
                            radius: 20, // adjust as needed
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: user['img'] ?? '',
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

                          title: Text(user['name'] ?? 'Unknown'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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

  var isBlockedByOther = false.obs;

  Future<void> checkIfBlockedByOther(String otherUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    try {
      final otherUserDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(otherUserId)
              .get();

      final otherBlockedList = List<String>.from(
        otherUserDoc.data()?['blocked'] ?? [],
      );

      isBlockedByOther.value = otherBlockedList.contains(currentUserId);
    } catch (e) {
      print("Error checking if blocked by other: $e");
      isBlockedByOther.value = false;
    }
  }

  Future cleanUpInvalidFollowersAndFollowing(String uid) async {
    final userRef = _firestore.collection('users');

    // Clean followers
    final followersSnapshot =
        await userRef.doc(uid).collection('followers').get();
    for (var doc in followersSnapshot.docs) {
      final followerId = doc.id;
      final userExists = await userRef
          .doc(followerId)
          .get()
          .then((d) => d.exists);
      if (!userExists) {
        await userRef.doc(uid).collection('followers').doc(followerId).delete();
        print('Deleted invalid follower: $followerId');
      }
    }

    // Clean following
    final followingSnapshot =
        await userRef.doc(uid).collection('following').get();
    for (var doc in followingSnapshot.docs) {
      final followingId = doc.id;
      final userExists = await userRef
          .doc(followingId)
          .get()
          .then((d) => d.exists);
      if (!userExists) {
        await userRef
            .doc(uid)
            .collection('following')
            .doc(followingId)
            .delete();
        print('Deleted invalid following: $followingId');
      }
    }
  }
}
