import 'package:banger_drop/views/auth/controllers/auth_controller.dart';
import 'package:banger_drop/views/utilities/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/Explore/explore_view.dart';
import 'package:banger_drop/views/widgets/buttons.dart';
import 'package:banger_drop/views/widgets/textfiled_widget.dart';
import 'package:banger_drop/views/widgets/bottom_navigation_bar/bottonBar.dart';
import 'package:banger_drop/views/auth/sign_in/widgets/social_icons_widgets.dart';

class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final AuthController controller = Get.put(AuthController());

  @override
  void dispose() {
    // _emailController.dispose();
    // _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColors.black,
      body: Obx(
        () => Stack(
          children: [
            Positioned.fill(
              child: Container(
                height: 500, // Set your desired height
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
                  padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 40.h),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: BackButton(color: appColors.white),
                        ),
                        SizedBox(height: 30.h),
                        Image.asset('assets/images/Group (2).png'),
                        SizedBox(height: 10.h),
                        Text(
                          'Welcome back',
                          textAlign: TextAlign.center,
                          style: appThemes.Large.copyWith(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          'Please enter your details to sign in',
                          textAlign: TextAlign.center,
                          style: appThemes.small.copyWith(
                            color: appColors.white.withOpacity(.8),
                          ),
                        ),
                        SizedBox(height: 20.h),
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
                        SizedBox(height: 20.h),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: appColors.pink,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: Text(
                                'OR',
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
                        SizedBox(height: 20.h),
                        CustomEmailField(
                          controller:
                              controller
                                  .usernameController
                                  .value, // ← important
                          hintText: 'Username or Email',
                        ),
                        SizedBox(height: 20.h),
                        CustomEmailField(
                          controller: controller.passController.value,
                          hintText: 'Password',
                          isPassword: true,
                        ),

                        SizedBox(height: 20.h),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40.w),
                          child: roundButton(
                            loading: controller.isLoading.value,
                            text: "Connect",
                            backgroundGradient: LinearGradient(
                              colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderColor: appColors.pink,
                            textColor: Colors.white,
                            onPressed: () async {
                              // Get.offAll(() => MainScreenView());
                              controller.loginWithUsernamePassword();
                            },
                          ),
                        ),
                        SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            // controller.deleteUsersWithoutUID();
                          },
                          child: Text(
                            'I forgot my password',
                            style: appThemes.Medium.copyWith(
                              color: appColors.white.withOpacity(.8),
                            ),
                          ),
                        ),

                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Positioned.fill(
            //   child: Image.asset(
            //     'assets/images/Wallpp (1).JPG',
            //     fit: BoxFit.cover,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
