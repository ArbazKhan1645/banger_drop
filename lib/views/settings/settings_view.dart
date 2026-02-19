import 'dart:convert';

import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/notifications/fcm_notification_sender.dart';
import 'package:banger_drop/notifications/get_serverKey.dart';
import 'package:banger_drop/notifications/notifications_services.dart';
import 'package:banger_drop/views/Notification/notification_view.dart';
import 'package:banger_drop/views/Security/security_view.dart';
import 'package:banger_drop/views/change_language/change_language.dart';
import 'package:banger_drop/views/confedentiality/confedantiality.dart';
import 'package:banger_drop/views/feedback/feedback_view.dart';
import 'package:banger_drop/views/forget_password/forget_password_view.dart';
import 'package:banger_drop/views/notification_setting/notification_setting_view.dart';
import 'package:banger_drop/views/personal_info/personal_info.dart';
import 'package:banger_drop/views/prefrences/prefrences.dart';
import 'package:banger_drop/views/settings/widgets/about_view.dart';
import 'package:banger_drop/views/settings/widgets/account_view.dart';
import 'package:banger_drop/views/settings/widgets/confedentiality_view.dart';
import 'package:banger_drop/views/settings/widgets/help_support_view.dart';
import 'package:banger_drop/views/settings/widgets/select_language_dailog.dart';
import 'package:banger_drop/views/spalsh/spalsh_screen.dart';
import 'package:banger_drop/views/widgets/bottom_navigation_bar/bottonBar.dart';
import 'package:banger_drop/views/widgets/loading_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/route_manager.dart';
import 'package:http/http.dart' as http;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationServices _notificationServices = NotificationServices();
  final FcmNotificationSender sender = FcmNotificationSender();

  final BottomNavController BottomBarcontroller =
      Get.find<BottomNavController>();
  final db = FirebaseFirestore.instance;
  bool _isLoggingOut = false;

  String currentTheme = 'Light';

  String currentLanguage = 'English'; // ✅ Initial language

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/images/Picture1.png',
                ), // Replace with your image path
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const BackButton(color: Colors.white),
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 50),
                    ],
                  ),

                  // Settings content
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),
                        SectionTitle(title: 'Settings and privacy'),
                        SettingsItem(
                          title: 'Account',
                          onTap: () {
                            Get.to(() => AccountScreen());
                          },
                        ),
                        SettingsItem(
                          title: 'Personal informations',
                          onTap: () {
                            Get.to(() => PersonalInfoView());
                          },
                        ),
                        SettingsItem(
                          title: 'Security',
                          onTap: () {
                            // Get.to(
                            //   () => ForgetPassword(
                            //     imageUrl:
                            //         'https://via.placeholder.com/150', // Replace with actual image URL
                            //     name: 'John Doe',
                            //     email: 'john.doe@example.com',
                            //     points: 120,
                            //   ),
                            // );
                            Get.to(() => SecurityScreen());
                          },
                        ),
                        SettingsItem(
                          title: 'Notifications',
                          onTap: () => Get.to(() => NotificationsScreen()),
                        ),
                        SettingsItem(
                          title: 'Confidentiality',
                          onTap: () => Get.to(() => ConfedentialitySetting()),
                        ),
                        SettingsItem(
                          title: 'Language',
                          onTap: () {
                            Get.to(() => LanguageSelectionScreen());
                            // showDialog(
                            //   context: context,
                            //   builder: (context) {
                            //     return LanguageDialog(
                            //       selectedLanguage: currentLanguage,
                            //       onLanguageSelected: (language) {
                            //         setState(() {
                            //           currentLanguage = language;
                            //           // Apply your localization logic here
                            //         });
                            //       },
                            //     );
                            //   },
                            // );
                          },
                        ),
                        SettingsItem(
                          title: 'Preferences',
                          onTap: () {
                            Get.to(() => Prefrences(fromSettings: true));
                          },
                        ),
                        const SizedBox(height: 24),
                        const SectionTitle(title: 'Display'),
                        SettingsItem(
                          title: 'Themes / appearance',
                          onTap: () async {
                            final targetToken = await sender
                                .fetchFcmTokensForUser(
                                  FirebaseAuth.instance.currentUser!.uid,
                                );
                            for (String token in targetToken) {
                              await sender.sendNotification(
                                title: "Hello there",
                                body: "This is a notification for Banger Drop",
                                targetToken: token,
                                dataPayload: {"type": "msg"},
                                uid: FirebaseAuth.instance.currentUser!.uid,
                              );
                            }
                          },
                        ),
                        SettingsItem(
                          title: 'Dark mode',
                          onTap: () {
                            Get.dialog(
                              ThemeDialog(
                                selectedTheme: currentTheme,
                                onThemeSelected: (theme) {
                                  setState(() {
                                    currentTheme = theme;
                                    // Optional: Save to local storage for persistence
                                  });
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        SectionTitle(
                          OnTap: () => Get.to(() => HelpAndSupport()),
                          title: 'Help & support',
                        ),
                        SectionTitle(
                          OnTap: () => Get.to(() => FeedbackView()),
                          title: 'Feedback',
                        ),
                        SectionTitle(
                          title: 'About',
                          OnTap: () {
                            Get.to(() => AboutScreen());
                          },
                        ),
                        _isLoggingOut
                            ? Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [LoadingWidget(color: appColors.white)],
                            )
                            : SectionTitle(
                              title: 'Log Out',
                              OnTap: () {
                                print('Log Out tapped');
                                logoutUser(FirebaseAuth.instance).then((val) {
                                  BottomBarcontroller.selectedIndex.value = 0;
                                  Get.offAll(
                                    transition: Transition.cupertino,
                                    duration: const Duration(seconds: 1),

                                    () => LogoAnimationScreen(),
                                  );
                                });
                                // Add logout logic here
                              },
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> logoutUser(dynamic auth) async {
    setState(() {
      _isLoggingOut = true;
    });

    final uid = auth.currentUser?.uid;
    final token = await _notificationServices.getDeviceToken();

    if (uid != null && token != null) {
      final docRef = db.collection('users').doc(uid);
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        final List<dynamic> existingDevices = snapshot.data()?['devices'] ?? [];

        // Filter out the current token from devices
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

        print("✅ Device removed from user's devices list");
      }
    }

    await auth.signOut();

    setState(() {
      _isLoggingOut = false; // ← previously this was still `true`
    });
  }

  // Future<void> logout() async {
  //   final userId = FirebaseAuth.instance.currentUser?.uid;
  //   if (userId != null) {
  //     await FirebaseFirestore.instance.collection('users').doc(userId).update({
  //       'isOnline': false,
  //       'lastSeen': FieldValue.serverTimestamp(),
  //     });
  //   }
  //   await FirebaseAuth.instance.signOut();
  // }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final OnTap;

  const SectionTitle({required this.title, super.key, this.OnTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, top: 6.0),
      child: GestureDetector(
        onTap: () {
          OnTap();
        },
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class SettingsItem extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const SettingsItem({required this.title, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          title,
          style: appThemes.Medium.copyWith(
            fontFamily: 'Sans',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class ThemeDialog extends StatelessWidget {
  final List<String> themes = ['Light', 'Dark'];
  final String selectedTheme;
  final Function(String) onThemeSelected;

  ThemeDialog({
    Key? key,
    required this.selectedTheme,
    required this.onThemeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String currentTheme = selectedTheme;

    return AlertDialog(
      backgroundColor: appColors.purple,
      title: Text('Select Theme', style: appThemes.Large),
      content: StatefulBuilder(
        builder: (context, setState) {
          return SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: themes.length,
              itemBuilder: (context, index) {
                final theme = themes[index];
                final isSelected = theme == currentTheme;

                return ListTile(
                  title: Text(
                    theme,
                    style: appThemes.Medium.copyWith(fontFamily: 'Sans'),
                  ),
                  trailing:
                      isSelected
                          ? Icon(
                            Icons.arrow_left_outlined,
                            color: appColors.white,
                          )
                          : null,
                  onTap: () {
                    setState(() {
                      currentTheme = theme;
                    });

                    // Notify parent
                    onThemeSelected(theme);

                    // Change the theme using GetX
                    if (theme == 'Light') {
                      Get.changeTheme(ThemeData.light());
                    } else {
                      Get.changeTheme(ThemeData.dark());
                    }

                    // Close the dialog after a slight delay
                    Future.delayed(const Duration(milliseconds: 150), () {
                      Navigator.of(context).pop();
                    });
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
