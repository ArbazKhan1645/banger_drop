import 'package:banger_drop/views/spalsh/spalsh_screen.dart';
import 'package:banger_drop/views/widgets/bottom_navigation_bar/bottonBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/get_core.dart';
import 'package:get/get_navigation/get_navigation.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool isDeactivated = false;
  bool isLoadingDeactivation = true; // for toggle loader

  Future<void> fetchDeactivationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final data = doc.data();
    if (data != null && data.containsKey('Deactivated')) {
      isDeactivated = data['Deactivated'] == true;
    } else {
      isDeactivated = false;
    }

    setState(() {
      isLoadingDeactivation = false;
    });
  }

  final BottomNavController BottomBarcontroller =
      Get.find<BottomNavController>();
  Future<void> deleteUserAndData(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final firestore = FirebaseFirestore.instance;

    try {
      // Show loader/dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // 1. Delete Bangers by CreatedBy
      final bangerDocs =
          await firestore
              .collection('Bangers')
              .where('CreatedBy', isEqualTo: uid)
              .get();
      for (var doc in bangerDocs.docs) {
        await doc.reference.delete();
      }

      // 2. Delete Playlists by CreatedBy
      final playlistDocs =
          await firestore
              .collection('Playlist')
              .where('created By', isEqualTo: uid)
              .get();
      for (var doc in playlistDocs.docs) {
        await doc.reference.delete();
      }

      // 3. ❌ REMOVE old sender/receiver logic
      // ✅ Delete chats where 'participants' array contains uid
      final chatsWithUser =
          await firestore
              .collection('chats')
              .where('participants', arrayContains: uid)
              .get();

      for (var doc in chatsWithUser.docs) {
        await doc.reference.delete();
      }

      // 4. Delete username doc where uid == uid
      final usernameDocs = await firestore.collection('usernames').get();
      for (var doc in usernameDocs.docs) {
        final data = doc.data();
        if (data['uid'] == uid) {
          await doc.reference.delete();
          break;
        }
      }

      // 5. Delete from users collection
      await firestore.collection('users').doc(uid).delete();

      // 6. Delete user from FirebaseAuth
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          Navigator.of(context).pop(); // close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please re-login to delete your account."),
            ),
          );

          await FirebaseAuth.instance.signOut();
          BottomBarcontroller.selectedIndex.value = 0;
          Get.offAll(() => LogoAnimationScreen());
          return;
        } else {
          rethrow;
        }
      }

      // ✅ Handle success flow AFTER deletion
      Navigator.of(context).pop(); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account deleted successfully")),
      );
      BottomBarcontroller.selectedIndex.value = 0;
      Get.offAll(() => LogoAnimationScreen());
    } catch (e) {
      Navigator.of(context).pop(); // close loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting account: $e")));
    }
  }

  Future<void> updateDeactivationStatus(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      isDeactivated = value;
    });

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'Deactivated': value,
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchDeactivationStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B0126),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isLoadingDeactivation
                ? const CircularProgressIndicator()
                : SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Deactivate Account',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Temporarily disable your account',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  value: isDeactivated,
                  activeColor: const Color(0xFFEA1CD6),
                  onChanged: (value) => updateDeactivationStatus(value),
                ),
            const Text(
              'By clicking on “Remove” you will permanently remove your account and all the data stored, are you sure you want to remove?',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text("Confirm Account Deletion"),
                          content: const Text(
                            "This action will permanently delete your account and all associated data. Are you sure you want to proceed?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEA1CD6),
                              ),
                              child: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                  );

                  if (confirm == true) {
                    await deleteUserAndData(context);
                  }
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA1CD6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Remove',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
