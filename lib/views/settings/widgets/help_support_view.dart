import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/Notification/notification_view.dart';
import 'package:banger_drop/views/forget_password/forget_password_view.dart';
import 'package:banger_drop/views/prefrences/prefrences.dart';
import 'package:banger_drop/views/settings/widgets/account_view.dart';
import 'package:banger_drop/views/settings/widgets/select_language_dailog.dart';
import 'package:banger_drop/views/spalsh/spalsh_screen.dart';
import 'package:banger_drop/views/spalsh/widgets/privacy_policy.dart';
import 'package:banger_drop/views/widgets/buttons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

class HelpAndSupport extends StatefulWidget {
  const HelpAndSupport({super.key});

  @override
  State<HelpAndSupport> createState() => _HelpAndSupportState();
}

class _HelpAndSupportState extends State<HelpAndSupport> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    'assets/images/Picture1.png',
                  ), // Replace with your image path
                  fit: BoxFit.cover,
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const BackButton(color: Colors.white),
                      Text('Help And Support', style: appThemes.Large),
                      const SizedBox(width: 50),
                    ],
                  ),
                  _sectionTitle('📄 Frequently Asked Questions'),
                  _helpItem(
                    title: 'How do I reset my password?',
                    description: 'Go to Settings > Account > Reset Password.',
                  ),
                  _helpItem(
                    title: 'How can I update my profile?',
                    description:
                        'Navigate to Profile and click on the edit icon.',
                  ),
                  _helpItem(
                    title: 'Is my data secure?',
                    description: 'Yes, we use encryption and secure storage.',
                  ),

                  const SizedBox(height: 24),

                  _sectionTitle('✉️ Contact Support'),
                  ListTile(
                    leading: Icon(Icons.email, color: appColors.white),
                    title: Text(
                      'bangerdropmusic@gmail.com',
                      style: appThemes.small.copyWith(),
                    ),
                    onTap: () {
                      // TODO: Implement email launch
                    },
                  ),

                  const SizedBox(height: 24),

                  _sectionTitle('🐞 Report a Problem'),
                  ListTile(
                    leading: Icon(Icons.bug_report, color: appColors.white),
                    title: Text(
                      'Report an issue',
                      style: appThemes.small.copyWith(),
                    ),
                    subtitle: Text(
                      'Tell us what went wrong',
                      style: appThemes.small.copyWith(
                        color: appColors.textGrey,
                        fontFamily: 'Sans',
                      ),
                    ),
                    onTap: () {
                      // TODO: Navigate to feedback/report screen
                    },
                  ),

                  const SizedBox(height: 24),

                  _sectionTitle('📚 How to Use the App'),
                  ListTile(
                    leading: Icon(Icons.video_library, color: appColors.white),
                    title: Text(
                      'Watch Tutorials',
                      style: appThemes.small.copyWith(),
                    ),
                    subtitle: Text(
                      'Step-by-step video guides',
                      style: appThemes.small.copyWith(
                        color: appColors.textGrey,
                        fontFamily: 'Sans',
                      ),
                    ),
                    onTap: () {
                      // TODO: Link to videos or in-app tutorial
                    },
                  ),

                  const SizedBox(height: 24),

                  _sectionTitle('📄 Legal'),
                  ListTile(
                    leading: Icon(Icons.privacy_tip, color: appColors.white),
                    title: Text(
                      'Privacy Policy',
                      style: appThemes.Medium.copyWith(),
                    ),
                    onTap: () {
                      Get.dialog(PrivacyPolicy());
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.description, color: appColors.white),
                    title: Text(
                      'Terms of Service',
                      style: appThemes.Medium.copyWith(),
                    ),
                    onTap: () {
                      // TODO: Open terms of service screen or URL
                    },
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: Text(
                      'App Version 1.0.0',
                      style: appThemes.small.copyWith(
                        color: appColors.textGrey,
                        fontFamily: 'Sans',
                      ),
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: appThemes.Medium),
    );
  }

  Widget _helpItem({required String title, required String description}) {
    return ListTile(
      leading: Icon(Icons.help_outline, color: appColors.white),
      title: Text(title, style: appThemes.small),
      subtitle: Text(
        description,
        style: appThemes.small.copyWith(
          color: appColors.textGrey,
          fontFamily: 'Sans',
        ),
      ),
    );
  }
}
