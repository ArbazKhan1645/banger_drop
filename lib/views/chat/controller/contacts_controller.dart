// 👇 Updated ContactsController to support Chat List and Invite List based on reply state

import 'dart:io';

import 'package:banger_drop/views/story/story_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactsController extends GetxController {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final searchQuery = ''.obs;
  final searchController = Rx<TextEditingController>(TextEditingController());

  final hasMyStory = false.obs;
  final myStoryData = Rxn<Map<String, dynamic>>();
  final isUploadingStory = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkStoriesAndCleanup();
    listenToInviteCount();
    listenToUnreadAndInvites();
  }

  void checkStoriesAndCleanup() {
    final now = Timestamp.now();

    FirebaseFirestore.instance.collection('stories').snapshots().listen((
      snapshot,
    ) {
      bool myStoryFound = false;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp;
        final diff = now.toDate().difference(createdAt.toDate());

        // ✅ Delete if older than 24 hours
        if (diff.inHours >= 24) {
          FirebaseFirestore.instance.collection('stories').doc(doc.id).delete();
          if (doc.id == currentUserId) {
            hasMyStory.value = false;
            myStoryData.value = null;
          }
        } else {
          // ✅ Check if this is current user's valid story
          if (doc.id == currentUserId) {
            myStoryFound = true;
            hasMyStory.value = true;
            myStoryData.value = data;
          }
        }
      }

      // ✅ If no story doc found for this user
      if (!myStoryFound) {
        hasMyStory.value = false;
        myStoryData.value = null;
      }
    });
  }

  Future<void> pickAndUploadStory(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'mp3'],
    );

    if (result == null) return;
    final file = result.files.first;
    final filePath = file.path!;

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Post Story?'),
        content: const Text('Do you want to post this story?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Post'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    isUploadingStory.value = true;

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final ref = FirebaseStorage.instance.ref().child('stories/$fileName');

      await ref.putFile(File(filePath));
      final downloadUrl = await ref.getDownloadURL();

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .get();
      final userData = userDoc.data() ?? {};

      await FirebaseFirestore.instance
          .collection('stories')
          .doc(currentUserId)
          .set({
            'uid': currentUserId,
            'url': downloadUrl,
            'type': file.extension == 'mp3' ? 'audio' : 'image',
            'createdAt': Timestamp.now(),
            'img': userData['img'] ?? '',
            'name': userData['name'] ?? 'User',
          });
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload story');
    } finally {
      isUploadingStory.value = false;
    }
  }

  void viewUserStory(String userId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('stories')
            .doc(userId)
            .get();
    if (!doc.exists) return;

    final storyData = doc.data()!;
    final type = storyData['type'];
    final url = storyData['url'];
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};

    Get.to(
      () => StoryViewer(
        type: type,
        url: url,
        userImage: userData['img'] ?? 'https://i.stack.imgur.com/l60Hf.png',
        userName: userData['name'] ?? 'User',
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> getChatUsersStream() {
    return FirebaseFirestore.instance.collection('chats').snapshots().asyncMap((
      chatSnapshot,
    ) async {
      final List<Map<String, dynamic>> result = [];

      for (var chatDoc in chatSnapshot.docs) {
        final chatData = chatDoc.data();
        final chatId = chatDoc.id;

        if (!chatId.contains(currentUserId)) continue;

        final replied = List<String>.from(chatData['repliedUsers'] ?? []);
        if (!replied.contains(currentUserId)) continue;

        final ids = chatId.split('_');
        final otherUserId = ids.firstWhere((id) => id != currentUserId);

        // Fetch other user’s profile
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(otherUserId)
                .get();
        final userData = userDoc.data();
        if (userData == null) continue;

        // 🔍 Count unread messages
        final messageQuery =
            await FirebaseFirestore.instance
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .where('senderId', isNotEqualTo: currentUserId)
                .get();

        int unreadCount = 0;

        for (var msg in messageQuery.docs) {
          final isReadBy = List<String>.from(msg['isReadBy'] ?? []);
          if (!isReadBy.contains(currentUserId)) {
            unreadCount++;
          }
        }

        userData['uid'] = otherUserId;
        userData['lastMessage'] = chatData['lastMessage'] ?? 'Say hi!';
        userData['lastMessageTime'] = chatData['lastMessageTime'];
        userData['unreadCount'] = unreadCount; // ✅ This is now dynamic

        result.add(userData);
      }

      // Sort by last message time
      result.sort((a, b) {
        final aTime = a['lastMessageTime'] as Timestamp?;
        final bTime = b['lastMessageTime'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.toDate().compareTo(aTime.toDate());
      });

      return result;
    });
  }

  // ✅ Invite List: where current user is participant but hasn't replied
  Stream<List<Map<String, dynamic>>> getInvitesStream() {
    return FirebaseFirestore.instance.collection('chats').snapshots().asyncMap((
      snapshot,
    ) async {
      final result = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final chatId = doc.id;

        if (!chatId.contains(currentUserId)) continue;

        final participants = List<String>.from(data['participants'] ?? []);
        final replied = List<String>.from(data['repliedUsers'] ?? []);

        if (!participants.contains(currentUserId) ||
            replied.contains(currentUserId))
          continue;

        final ids = chatId.split('_');
        final otherId = ids.firstWhere((id) => id != currentUserId);
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(otherId)
                .get();

        if (!userDoc.exists) continue;

        final userData = userDoc.data()!;
        userData['uid'] = otherId;
        userData['lastMessage'] = data['lastMessage'] ?? 'Say hi!';
        userData['lastMessageTime'] = data['lastMessageTime'];
        result.add(userData);
      }

      result.sort(
        (a, b) =>
            (b['lastMessageTime'] as Timestamp?)?.compareTo(
              a['lastMessageTime'],
            ) ??
            0,
      );
      return result;
    });
  }

  Stream<List<Map<String, dynamic>>> getAllUsersForSearch() {
    return FirebaseFirestore.instance.collection('users').snapshots().map((
      snapshot,
    ) {
      final allUsers =
          snapshot.docs
              .where(
                (doc) =>
                    doc.id != currentUserId &&
                    (doc.data()['Deactivated'] != true),
              ) // ⛔ Exclude deactivated users
              .map((doc) {
                final data = doc.data();
                data['uid'] = doc.id;
                return data;
              })
              .toList();

      // 🔍 Apply search filtering if query is not empty
      if (searchQuery.value.trim().isEmpty) return allUsers;

      final query = searchQuery.value.toLowerCase();
      return allUsers.where((user) {
        final name = (user['name'] ?? '').toLowerCase();
        final username = (user['username'] ?? '').toLowerCase();
        return name.contains(query) || username.contains(query);
      }).toList();
    });
  }

  final inviteCount = 0.obs;

  void listenToInviteCount() {
    FirebaseFirestore.instance.collection('chats').snapshots().listen((
      snapshot,
    ) async {
      int count = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final chatId = doc.id;

        if (!chatId.contains(currentUserId)) continue;

        final participants = List<String>.from(data['participants'] ?? []);
        final repliedUsers = List<String>.from(data['repliedUsers'] ?? []);

        if (!participants.contains(currentUserId)) continue;
        if (repliedUsers.contains(currentUserId)) continue;

        count++;
      }

      inviteCount.value = count;
    });
  }

  final RxInt totalUnread = 0.obs;
  final Map<String, int> chatUnreadCounts = {};

  void listenToUnreadAndInvites() {
    FirebaseFirestore.instance.collection('chats').snapshots().listen((
      chatSnapshot,
    ) {
      for (var chatDoc in chatSnapshot.docs) {
        final chatId = chatDoc.id;

        if (!chatId.contains(currentUserId)) continue;

        FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .snapshots()
            .listen((messageSnapshot) {
              int unread = 0;

              for (var msg in messageSnapshot.docs) {
                final isReadBy = List<String>.from(msg['isReadBy'] ?? []);
                final senderId = msg['senderId'];

                if (senderId != currentUserId &&
                    !isReadBy.contains(currentUserId)) {
                  unread++;
                }
              }

              // Update per-chat unread count
              chatUnreadCounts[chatId] = unread;

              // Recalculate total unread
              totalUnread.value = chatUnreadCounts.values.fold(
                0,
                (a, b) => a + b,
              );
            });
      }
    });
  }

  String generateChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }
}
