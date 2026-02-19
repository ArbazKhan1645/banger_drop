import 'package:banger_drop/views/Explore/explore_view.dart';
import 'package:banger_drop/views/auth/controllers/auth_controller.dart';
import 'package:banger_drop/views/auth/sign_in/widgets/social_icons_widgets.dart';
import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/prefrences/prefrences.dart';
import 'package:banger_drop/views/utilities/utilities.dart';
import 'package:banger_drop/views/widgets/bottom_navigation_bar/bottonBar.dart';
import 'package:banger_drop/views/widgets/buttons.dart';
import 'package:banger_drop/views/widgets/textfiled_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final user = FirebaseAuth.instance.currentUser?.uid;
  final AuthController controller = Get.put(AuthController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // So background image is visible
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   automaticallyImplyLeading: false,
      //   leading: BackButton(color: appColors.white),
      // ),
      body: Obx(
        () => Stack(
          children: [
            // 🔽 Background Image
            Positioned.fill(
              child: Container(
                // height: 160, // Set your desired height
                width: double.infinity, // Full width
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/Wallpp (1).JPG',
                    ), // Replace with your image path
                    fit:
                        BoxFit
                            .cover, // Adjust image fit: cover, contain, fill, etc.
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        Row(children: [BackButton(color: appColors.white)]),
                        const SizedBox(height: 16),

                        Image.asset('assets/images/Group (2).png', height: 80),
                        const SizedBox(height: 30),
                        Text(
                          'Welcome',
                          textAlign: TextAlign.center,
                          style: appThemes.Large.copyWith(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Please enter your details to sign up',
                          textAlign: TextAlign.center,
                          style: appThemes.small.copyWith(
                            color: appColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SocialIconsRow(
                          googleIconPath: 'assets/images/Group 1000000757.png',
                          facebookIconPath:
                              'assets/images/Group 1000000758.png',
                          appleIconPath: 'assets/images/Group 1000000759.png',
                          twitterIconPath: 'assets/images/Group 1000000760.png',
                          onGoogleTap: () async {
                            await controller.signUpWithGoogle(context);
                          },
                          onFacebookTap: () {
                            controller.signUpWithFacebook();
                          },
                          onAppleTap: () async {
                            try {
                              await controller.signUpWithApple(context);
                            } catch (e) {
                              Utilities.successMessege(
                                'Failed',
                                'Failed During Apple Sign Up',
                              ); // Show error dialog/snackbar
                            }
                          },
                          onTwitterTap: () => print('Twitter tapped'),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: appColors.pink,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'OR',
                                textAlign: TextAlign.center,
                                style: appThemes.Medium.copyWith(
                                  color: appColors.textGrey,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: appColors.pink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CustomEmailField(
                          isPassword: false,

                          controller: controller.usernameController.value,
                          hintText: 'Username',
                        ),
                        const SizedBox(height: 16),
                        CustomEmailField(
                          controller: controller.emailController.value,
                          hintText: 'E-mail',
                        ),
                        const SizedBox(height: 16),
                        CustomEmailField(
                          isPassword: true,

                          controller: controller.passController.value,
                          hintText: 'Password',
                        ),
                        const SizedBox(height: 16),
                        CustomEmailField(
                          isPassword: true,
                          controller: controller.ConfirmPassController.value,
                          hintText: 'Re-Enter Password',
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: roundButton(
                            loading: controller.isLoading.value,
                            text: "Create",
                            backgroundGradient: const LinearGradient(
                              colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderColor: appColors.pink,
                            textColor: Colors.white,
                            onPressed: () {
                              controller.signUpWithEmailPassword().then((val) {
                                if (val != null) {
                                  AppConstants.initializeUserData(); // Correct method
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 🔼 Foreground Content
          ],
        ),
      ),
    );
  }
}
