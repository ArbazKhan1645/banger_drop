import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class InvitesController extends GetxController {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final invites = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInvites();
  }

  void fetchInvites() {
    isLoading.value = true;

    FirebaseFirestore.instance.collection('chats').snapshots().listen((
      snapshot,
    ) async {
      final List<Map<String, dynamic>> temp = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final chatId = doc.id;

        if (!chatId.contains(currentUserId)) continue;

        final participants = List<String>.from(data['participants'] ?? []);
        final repliedUsers = List<String>.from(data['repliedUsers'] ?? []);

        if (!participants.contains(currentUserId)) continue;
        if (repliedUsers.contains(currentUserId)) continue;

        final ids = chatId.split('_');
        final otherUserId = ids.firstWhere((id) => id != currentUserId);

        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(otherUserId)
                .get();
        if (!userDoc.exists) continue;

        final userData = userDoc.data()!;
        temp.add({
          'uid': otherUserId,
          'name': userData['name'] ?? 'Unknown',
          'img': userData['img'] ?? '',
          'sentAt': data['lastMessageTime'],
        });
      }

      invites.value = temp;
      isLoading.value = false;
    });
  }

  Future<void> acceptInvite(String chatId) async {
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'repliedUsers': FieldValue.arrayUnion([currentUserId]),
      'rejectedUsers': FieldValue.arrayRemove([currentUserId]), // cleanup
    }, SetOptions(merge: true));

    Get.snackbar('Success', 'Invite accepted');
  }

  Future<void> rejectInvite(String chatId) async {
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayRemove([currentUserId]),
    });

    invites.removeWhere(
      (invite) => chatId == buildChatId(currentUserId, invite['uid']),
    );

    Get.snackbar('Ignored', 'Invite rejected');
  }

  String buildChatId(String id1, String id2) {
    final sorted = [id1, id2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
