import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/notifications/fcm_notification_sender.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FcmNotificationSender sender = FcmNotificationSender();

  Future<bool> fetchNotificationPreference(String fieldName, String uid) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

    try {
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          if (data.containsKey(fieldName)) {
            return data[fieldName] as bool;
          }
        }
      }
    } catch (e) {
      print('Error fetching $fieldName from Firestore: $e');
    }

    return true;
  }

  final isSending = false.obs;
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  late String chatId;
  late String otherUserId;

  Stream<QuerySnapshot>? messageStream;

  void initialize(String otherUser) {
    otherUserId = otherUser;
    chatId = _generateChatId(currentUserId, otherUserId);
    messageStream =
        FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('timestamp', descending: false)
            .snapshots();
    checkInboxAccess(); // 👈 Add this
  }

  // Helper method to scroll to bottom
  void scrollToBottom({bool animate = true}) {
    if (scrollController.hasClients) {
      if (animate) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    }
  }

  final canSendMessage = false.obs;

  Future<void> checkInboxAccess() async {
    try {
      final otherUserDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(otherUserId)
              .get();

      final restrictedInbox = otherUserDoc.data()?['restrictedInbox'] ?? false;

      if (!restrictedInbox) {
        canSendMessage.value = true;
        return;
      }

      // Check if either:
      // 1. current user is in otherUser's followers
      // 2. other user is in currentUser's followers
      final otherHasMe =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(otherUserId)
              .collection('followers')
              .doc(currentUserId)
              .get();

      final iHaveOther =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .collection('followers')
              .doc(otherUserId)
              .get();

      canSendMessage.value = otherHasMe.exists || iHaveOther.exists;
    } catch (e) {
      print('Error checking inbox access: $e');
      canSendMessage.value = false;
    }
  }

  Future<void> sendAudioMessage({
    required String receiverId,
    required String audioUrl,
    required String title,
    String? description,
    required String? bangerId,
    required String? img,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final chatId = _generateChatId(currentUserId, receiverId);
    final timestamp = FieldValue.serverTimestamp();
    final now = Timestamp.now();

    // Add the message to Firestore
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': currentUserId,
          'type': 'audio',
          'audioUrl': audioUrl,
          'title': title,
          'description': description ?? '',
          'bangerId': bangerId ?? '',
          'timestamp': timestamp,
          'isReadBy': [],
          'likedBy': [],
          'img': img ?? '',
        });

    // Update chat metadata
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'lastMessage': '[Audio] $title',
      'lastMessageTime': timestamp,
      'participants': [currentUserId, receiverId],
      'repliedUsers': FieldValue.arrayUnion([currentUserId]),
    }, SetOptions(merge: true));

    // Handle points if banger is shared
    if (bangerId != null && bangerId.isNotEmpty) {
      final bangerRef = FirebaseFirestore.instance
          .collection('Bangers')
          .doc(bangerId);
      final bangerSnap = await bangerRef.get();

      if (bangerSnap.exists) {
        final bangerData = bangerSnap.data()!;
        final createdBy = bangerData['CreatedBy'];
        final bangerImg = bangerData['imageUrl'] ?? '';

        await bangerRef.update({
          'TotalShares': FieldValue.increment(1),
          'shares': FieldValue.arrayUnion([
            {
              'userId': currentUserId,
              'name': AppConstants.userName,
              'userImg': AppConstants.userImg,
              'sharedAt': now,
            },
          ]),
        });

        if (createdBy != currentUserId) {
          final createdByRef = FirebaseFirestore.instance
              .collection('users')
              .doc(createdBy);
          await createdByRef.set({
            'points': FieldValue.increment(10),
            'pointsHistory': FieldValue.arrayUnion([
              {
                'points': 10,
                'reason': 'Banger shared via private message',
                'timestamp': now,
                'bangerId': bangerId,
                'sharedBy': currentUserId,
              },
            ]),
          }, SetOptions(merge: true));
        }

        // await addNotification(
        //   isPlayList: false,
        //   bangerId: bangerId,
        //   bangerOwnerId: createdBy,
        //   actionType: 'share',
        //   userId: currentUserId,
        //   userName: AppConstants.userName,
        //   userImg: AppConstants.userImg,
        //   bangerImg: bangerImg,
        // );
      }
    }

    // Auto-scroll after sending audio message
    Future.delayed(const Duration(milliseconds: 100), () {
      scrollToBottom();
    });

    Get.snackbar('Success', 'Banger sent successfully');
  }

  Future<void> addNotification({
    required String bangerId,
    required String bangerOwnerId,
    required String actionType,
    required String userId,
    required String userName,
    required String userImg,
    required String bangerImg,
    required bool isPlayList,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

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
      await firestore.collection('notifications').add({
        "bangerId": bangerId,
        'isPlayList': isPlayList,
        "bangerOwnerId": bangerOwnerId,
        "type": actionType,
        "users": [userMap],
        "bangerImg": bangerImg,
        "timestamp": Timestamp.now(),
        "seenBy": [],
      });
    }
  }

  String _generateChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    isSending.value = true;

    final timestamp = FieldValue.serverTimestamp();

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': currentUserId,
            'text': text,
            'timestamp': timestamp,
            'likedBy': [],
            'isReadBy': [],
          });

      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'lastMessage': text,
        'lastMessageTime': timestamp,
        'participants': [currentUserId, otherUserId],
        'repliedUsers': FieldValue.arrayUnion([currentUserId]),
      }, SetOptions(merge: true));

      messageController.clear();

      // Auto-scroll after sending message
      Future.delayed(const Duration(milliseconds: 100), () {
        scrollToBottom();
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      isSending.value = false;
    }
  }

  Future sendMessageNotification(
    String uid,
    String otherUserUid,
    String img,
    String name,
  ) async {
    if (await fetchNotificationPreference('messages', otherUserUid)) {
      final targetToken = await sender.fetchFcmTokensForUser(otherUserUid);
      for (String token in targetToken) {
        await sender.sendNotification(
          title: "New Message - ${name}",
          body: "New messages from ${AppConstants.userName}",
          targetToken: token,
          dataPayload: {"type": "chat", 'img': img, 'name': name, 'uid': uid},
          uid: uid,
        );
      }
    }
  }

  Future<void> sendPlaylistMessage({
    required String receiverId,
    required String playlistId,
    required String title,
    String? imageUrl,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final chatId = _generateChatId(currentUserId, receiverId);
    final timestamp = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': currentUserId,
          'type': 'playlist',
          'playlistId': playlistId,
          'title': title,
          'imageUrl': imageUrl ?? '',
          'timestamp': timestamp,
          'likedBy': [],
          'isReadBy': [],
        });

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'lastMessage': '[Playlist] $title',
      'lastMessageTime': timestamp,
      'participants': [currentUserId, receiverId],
      'repliedUsers': FieldValue.arrayUnion([currentUserId]),
    }, SetOptions(merge: true));

    final playlistRef = FirebaseFirestore.instance
        .collection('Playlist')
        .doc(playlistId);
    final currentUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId);

    final playlistSnap = await playlistRef.get();
    final playlistData = playlistSnap.data();

    if (playlistData != null) {
      final createdBy = playlistData['created By'];
      final totalShares = (playlistData['TotalShares'] ?? 0) + 1;

      await playlistRef.update({
        'TotalShares': totalShares,
        'shares': FieldValue.arrayUnion([
          {
            'img': AppConstants.userImg,
            'userId': currentUserId,
            'name': FirebaseAuth.instance.currentUser?.displayName ?? '',
            'sharedAt': Timestamp.now(),
          },
        ]),
      });

      await currentUserRef.set({
        'points': FieldValue.increment(10),
      }, SetOptions(merge: true));

      if (createdBy != currentUserId) {
        await FirebaseFirestore.instance.collection('users').doc(createdBy).set(
          {'points': FieldValue.increment(5)},
          SetOptions(merge: true),
        );
      }

      // await addNotification(
      //   isPlayList: true,
      //   bangerId: playlistId,
      //   bangerOwnerId: createdBy,
      //   actionType: 'share',
      //   userId: AppConstants.userId,
      //   userName: AppConstants.userName,
      //   userImg: playlistData['UserImage'] ?? '',
      //   bangerImg: playlistData['imageUrl'] ?? '',
      // );

      // final targetToken = await sender.fetchFcmTokensForUser(createdBy);

      // for (String token in targetToken) {
      //   await sender.sendNotification(
      //     title: "Playlist shared",
      //     body: "${AppConstants.userName} shared your Playlist",
      //     targetToken: token,
      //     dataPayload: {"type": "social"},
      //     uid: createdBy,
      //   );
      // }
    }

    // Auto-scroll after sending playlist message
    Future.delayed(const Duration(milliseconds: 100), () {
      scrollToBottom();
    });

    Get.snackbar('Shared', 'Playlist shared successfully');
  }

  void markMessagesAsRead() async {
    final query =
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('senderId', isNotEqualTo: currentUserId)
            .get();

    for (var doc in query.docs) {
      final data = doc.data();
      final isReadBy = List<String>.from(data['isReadBy'] ?? []);

      if (!isReadBy.contains(currentUserId)) {
        await doc.reference.update({
          'isReadBy': FieldValue.arrayUnion([currentUserId]),
        });
      }
    }
  }

  var isBlockedByYou = false.obs;
  var isBlockedByOther = false.obs;
  var isBlockStatusChecked = false.obs;

  Future<void> blockUser(String otherUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final usersRef = FirebaseFirestore.instance.collection('users');

    final currentUserDoc = await usersRef.doc(currentUserId).get();
    final currentBlockedList = List<String>.from(
      currentUserDoc.data()?['blocked'] ?? [],
    );

    if (!currentBlockedList.contains(otherUserId)) {
      currentBlockedList.add(otherUserId);
      await usersRef.doc(currentUserId).update({'blocked': currentBlockedList});
    }

    isBlockedByYou.value = true;
  }

  Future<void> checkBlockStatus(String otherUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final usersRef = FirebaseFirestore.instance.collection('users');

    try {
      final currentUserDoc = await usersRef.doc(currentUserId).get();
      final otherUserDoc = await usersRef.doc(otherUserId).get();

      final currentBlocked = List<String>.from(
        currentUserDoc.data()?['blocked'] ?? [],
      );
      final otherBlocked = List<String>.from(
        otherUserDoc.data()?['blocked'] ?? [],
      );

      isBlockedByYou.value = currentBlocked.contains(otherUserId);
      isBlockedByOther.value = otherBlocked.contains(currentUserId);
    } catch (e) {
      print('Error checking block status: $e');
    } finally {
      isBlockStatusChecked.value = true;
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
