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

class ConfedentialityView extends StatefulWidget {
  const ConfedentialityView({super.key});

  @override
  State<ConfedentialityView> createState() => _ConfedentialityViewState();
}

class _ConfedentialityViewState extends State<ConfedentialityView> {
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
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const BackButton(color: Colors.white),
                        const Text(
                          'Confidentiality Notice',
                          style: TextStyle(
                            fontSize: 24,
                            // fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                    const SizedBox(height: 30),

                    Text('''Confidential Information Agreement:
                
                You are about to access content and data that may include confidential, proprietary, or sensitive information. This information is intended solely for authorized users and should not be shared, distributed, or disclosed to any unauthorized person or third party.
                
                By continuing, you acknowledge and agree to treat all information obtained through this application as confidential. Unauthorized use or disclosure may result in disciplinary, legal, or financial consequences.
                
                  ''', style: appThemes.Medium.copyWith(fontFamily: 'Sans')),

                    GestureDetector(
                      onTap: () {
                        Get.dialog(PrivacyPolicy());
                      },
                      child: Stack(
                        children: [
                          Text(
                            ' Review organization’s privacy policies.',
                            style: appThemes.Medium.copyWith(
                              fontFamily: 'Sans',
                              fontStyle: FontStyle.italic,
                              color: appColors.textGrey,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 4,
                            right: 0,
                            child: Container(
                              height: 1,
                              color: appColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    roundButton(
                      text: "Continue",
                      backgroundGradient: LinearGradient(
                        colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderColor: appColors.white,
                      textColor: appColors.white,
                      onPressed: () {
                        Get.back();
                      },
                    ),
                    SizedBox(height: 10),
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
