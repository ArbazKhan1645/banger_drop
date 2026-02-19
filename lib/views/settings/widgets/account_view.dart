import 'dart:io';
import 'dart:ui';

import 'package:banger_drop/notifications/notifications_services.dart';
import 'package:banger_drop/views/personal_info/personal_info.dart';
import 'package:banger_drop/views/settings/devices/devices.dart';
import 'package:banger_drop/views/settings/widgets/remove_account.dart';
import 'package:banger_drop/views/spalsh/spalsh_screen.dart';
import 'package:banger_drop/views/widgets/bottom_navigation_bar/bottonBar.dart';
import 'package:banger_drop/views/widgets/loading_widget.dart';
import 'package:banger_drop/views/widgets/profile_textfield_wifget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_typedefs/rx_typedefs.dart';
import 'package:image_picker/image_picker.dart';
import 'package:banger_drop/consts/consts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AccountScreen extends StatelessWidget {
  AccountScreen({Key? key}) : super(key: key);
  final BottomNavController BottomBarcontroller =
      Get.find<BottomNavController>();
  final controller = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/Picture1.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        BackButton(color: appColors.white),
                        const Spacer(),
                        Obx(() {
                          return controller.hasUnsavedChanges.value
                              ? TextButton(
                                onPressed: () {
                                  controller.updateUsername(
                                    controller.nameController.text,
                                  );
                                },
                                child: const Text(
                                  "Save",
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                              : const SizedBox.shrink();
                        }),
                      ],
                    ),
                    // const SizedBox(height: 100),

                    // Profile Image
                    Obx(() {
                      return GestureDetector(
                        onTap: controller.pickAndUploadImage,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Profile image
                            ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: controller.profileImageUrl.value,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) =>
                                        const CircularProgressIndicator(),
                                errorWidget:
                                    (context, url, error) => Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        color: Colors.grey.shade300,
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        size: 70.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                              ),
                            ),

                            // Loading overlay
                            if (controller.isLoading.value)
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                            // Edit icon (bottom right)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 25.w,
                                height: 25.h,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 10),

                    ProfileField(
                      active: true,
                      title: 'Username',
                      controller: controller.nameController,
                      onChanged: (_) => controller.onFieldChanged(),
                    ),
                    const SizedBox(height: 12),
                    ProfileField(
                      active: false,
                      title: 'Email',
                      controller: controller.emailController,
                      onChanged: (_) => controller.onFieldChanged(),
                    ),

                    const SizedBox(height: 16),

                    // Points Card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 10,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber),
                            const SizedBox(width: 10),
                            Obx(
                              () => Text(
                                ' Collected: ${controller.points.value}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(children: [Text('Link with:', style: appThemes.small)]),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        GestureDetector(
                          onTap: () {
                            controller.showLinkDialog(
                              context: context,
                              platformName: 'Spotify',
                            );
                          },
                          child: Image.asset(
                            'assets/images/spotify-color-svgrepo-com 1.png',
                            width: 60.w,
                            height: 60.h,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            controller.showLinkDialog(
                              context: context,
                              platformName: 'YouTube',
                            );
                          },
                          child: Image.asset(
                            'assets/images/youtube-svgrepo-com 1.png',
                            width: 60.w,
                            height: 60.h,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 25.h),
                    tabWidget(
                      text: 'Professional account',
                      ontap: () {
                        Get.to(() => ());
                      },
                    ),
                    tabWidget(text: 'Share account', ontap: () {}),
                    tabWidget(
                      text: 'Sign out',
                      ontap: () {
                        print('Log Out tapped');
                        controller.logoutUser(FirebaseAuth.instance).then((
                          val,
                        ) {
                          BottomBarcontroller.selectedIndex.value = 0;
                          Get.offAll(
                            transition: Transition.cupertino,
                            duration: const Duration(seconds: 1),

                            () => LogoAnimationScreen(),
                          );
                        });
                      },
                    ),
                    tabWidget(
                      text: 'Delete account',
                      ontap: () {
                        Get.to(() => DeleteAccountScreen());
                      },
                    ),
                    tabWidget(
                      text: 'Devices',
                      ontap: () {
                        Get.to(
                          () => DevicesView(
                            uid: FirebaseAuth.instance.currentUser!.uid,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileController extends GetxController {
  RxString profileImageUrl = (AppConstants.userImg ?? '').obs;
  RxBool isLoading = false.obs;
  RxString points = (AppConstants.points ?? '0').obs;
  final db = FirebaseFirestore.instance;
  final NotificationServices _notificationServices = NotificationServices();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final RxBool hasUnsavedChanges = false.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void onFieldChanged() {
    hasUnsavedChanges.value = true;
  }

  @override
  void onInit() {
    super.onInit();
    fetchUserData(AppConstants.userId);
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    super.onClose();
  }

  void showLinkDialog({
    required BuildContext context,
    required String platformName,
  }) async {
    final TextEditingController linkController = TextEditingController();
    final userDoc =
        await _firestore.collection('users').doc(AppConstants.userId).get();

    final existingLink = userDoc.data()?[platformName.toLowerCase()] ?? '';
    linkController.text = existingLink;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Link your $platformName account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Styled TextField
                    TextField(
                      controller: linkController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        hintText: 'Enter your $platformName link',
                        hintStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final link = linkController.text.trim();
                        if (link.isNotEmpty) {
                          await _firestore
                              .collection('users')
                              .doc(AppConstants.userId)
                              .update({platformName.toLowerCase(): link});
                          Get.back();
                          Get.snackbar("Success", "$platformName link saved");
                        } else {
                          Get.snackbar("Error", "Link cannot be empty");
                        }
                      },
                      child: const Text(
                        'Save',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> fetchUserData(String userId) async {
    try {
      final docSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        nameController.text = data['username'] ?? '';
        emailController.text = data['email'] ?? '';
        profileImageUrl.value = data['img'] ?? '';
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> logoutUser(dynamic auth) async {
    // Show loading dialog
    Get.dialog(
      Center(child: LoadingWidget(color: appColors.white)),
      barrierDismissible: false,
    );

    try {
      final uid = auth.currentUser?.uid;
      final token = await _notificationServices.getDeviceToken();

      if (uid != null && token != null) {
        final docRef = db.collection('users').doc(uid);
        final snapshot = await docRef.get();

        if (snapshot.exists) {
          final List<dynamic> existingDevices =
              snapshot.data()?['devices'] ?? [];

          // Remove the device with matching token
          final updatedDevices =
              existingDevices
                  .where((device) => device['token'] != token)
                  .toList();

          await docRef.update({
            'fcmTokens': FieldValue.arrayRemove([token]),
            'devices': updatedDevices,
            'isOnline': false,
            'lastSeen': FieldValue.serverTimestamp(),
          });

          print("✅ Removed FCM token and device from user data");
        }
      }

      await auth.signOut();
      print("✅ User signed out");

      // Dismiss loader and navigate
      Get.back(); // Close dialog
    } catch (e) {
      print("❌ Logout failed: $e");
      Get.back(); // Close dialog
      Get.snackbar("Logout Error", e.toString());
    }
  }

  // Future<void> saveProfileChanges() async {
  //   try {
  //     await _firestore.collection('users').doc(AppConstants.userId).update({
  //       'name': nameController.text.trim(),
  //       'email': emailController.text.trim(),
  //     });

  //     hasUnsavedChanges.value = false;
  //     Get.snackbar("Saved", "Profile updated successfully");
  //   } catch (e) {
  //     Get.snackbar("Error", "Failed to save changes: $e");
  //   }
  // }

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      isLoading.value = true;
      final file = File(pickedFile.path);
      final fileName =
          '${AppConstants.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(
        'profile_images/$fileName',
      );

      try {
        await ref.putFile(file);
        final downloadUrl = await ref.getDownloadURL();

        final docRef = _firestore.collection('users').doc(AppConstants.userId);
        final docSnapshot = await docRef.get();
        final alreadyHasImage = docSnapshot.data()?['img'] != null;

        final updateData = <String, dynamic>{'img': downloadUrl};

        if (!alreadyHasImage) {
          updateData['points'] = FieldValue.increment(25);
          updateData['pointsHistory'] = FieldValue.arrayUnion([
            {
              'points': 25,
              'reason': 'Uploaded profile image',
              'timestamp': Timestamp.now(),
            },
          ]);
        }

        await docRef.update(updateData);

        profileImageUrl.value = downloadUrl;
        AppConstants.userImg = downloadUrl;

        final updatedSnapshot = await docRef.get();
        final updatedData = updatedSnapshot.data();
        if (updatedData != null && updatedData.containsKey('points')) {
          final newPoints = updatedData['points'].toString();
          AppConstants.points = newPoints;
          points.value = newPoints;
        }

        final bangerQuery =
            await _firestore
                .collection('Bangers')
                .where('CreatedBy', isEqualTo: AppConstants.userId)
                .get();

        final batch = _firestore.batch();
        for (final doc in bangerQuery.docs) {
          batch.update(doc.reference, {'UserImage': downloadUrl});
        }
        await batch.commit();
      } catch (e) {
        Get.snackbar("Error", "Failed to upload image: $e");
      } finally {
        isLoading.value = false;
      }
    }
  }

  Future<void> updateUsername(String newUsername) async {
    final userId = AppConstants.userId;
    final usernamesRef = _firestore.collection('usernames');
    final userDocRef = _firestore.collection('users').doc(userId);

    try {
      // Check if new username is already taken
      final newUsernameDoc = await usernamesRef.doc(newUsername).get();
      if (newUsernameDoc.exists) {
        Get.snackbar("Error", "Username already taken.");
        return;
      }

      // Fetch user data to get old username
      final userDoc = await userDocRef.get();
      if (!userDoc.exists) {
        Get.snackbar("Error", "User not found.");
        return;
      }

      final oldUsername = userDoc.data()?['username'];
      if (oldUsername == null || oldUsername.isEmpty) {
        Get.snackbar("Error", "Old username not found.");
        return;
      }

      // Fetch the old username doc to preserve UID and email
      final oldUsernameDoc = await usernamesRef.doc(oldUsername).get();
      if (!oldUsernameDoc.exists) {
        Get.snackbar("Error", "Old username document not found.");
        return;
      }

      final oldData = oldUsernameDoc.data();
      if (oldData == null) {
        Get.snackbar("Error", "Old username data is missing.");
        return;
      }

      // Start a Firestore batch operation
      final batch = _firestore.batch();

      // 1. Update username in users collection
      batch.update(userDocRef, {'username': newUsername, 'name': newUsername});

      // 2. Delete old username document
      batch.delete(usernamesRef.doc(oldUsername));

      // 3. Create new username document with same uid and email
      batch.set(usernamesRef.doc(newUsername), {
        'uid': oldData['uid'],
        'email': oldData['email'],
      });

      // Commit changes
      await batch.commit();

      Get.snackbar("Success", "Username updated successfully.");
    } catch (e) {
      Get.snackbar("Error", "Failed to update username: $e");
    }
  }
}

class tabWidget extends StatelessWidget {
  const tabWidget({super.key, required this.ontap, required this.text});

  final String text;
  final Callback ontap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ontap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Colors.white),
          Container(
            width: double.infinity, // make it take full width
            padding: const EdgeInsets.all(12.0),
            child: Text(
              text,
              style: appThemes.small.copyWith(color: appColors.pink),
            ),
          ),
        ],
      ),
    );
  }
}
