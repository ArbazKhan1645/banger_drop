import 'dart:convert';
import 'dart:math';

import 'package:banger_drop/firebase_options.dart';
import 'package:banger_drop/notifications/get_serverKey.dart';
import 'package:banger_drop/notifications/notifications_services.dart';
import 'package:banger_drop/views/Explore/explore_view.dart';
import 'package:banger_drop/views/auth/sign_Up/sign_up_view.dart';
import 'package:banger_drop/views/auth/sign_in/sign_in_view.dart';
import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/leaderboard/widgets/ranking_info.dart';
import 'package:banger_drop/views/spalsh/widgets/privacy_policy.dart';
import 'package:banger_drop/views/widgets/bottom_navigation_bar/bottonBar.dart';
import 'package:banger_drop/views/widgets/buttons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class LogoAnimationScreen extends StatefulWidget {
  @override
  _LogoAnimationScreenState createState() => _LogoAnimationScreenState();
}

class _LogoAnimationScreenState extends State<LogoAnimationScreen>
    with TickerProviderStateMixin {
  bool showWhiteLogo = false;
  bool showTextLogo = false;
  bool showFirstContainer = false;
  bool showSecondContainer = false;
  double logoLeft = 0;
  late AnimationController _textController;
  late AnimationController _firstContainerController;
  late AnimationController _secondContainerController;
  late Animation<double> _textWidth;
  late Animation<double> _textOpacity;
  late Animation<Offset> _firstContainerSlide;
  late Animation<double> _firstContainerOpacity;
  late Animation<Offset> _secondContainerSlide;
  late Animation<double> _secondContainerOpacity;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _firstContainerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300), // Faster animation
    );

    _secondContainerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300), // Faster animation
    );

    // First container animations
    _firstContainerSlide = Tween<Offset>(
      begin: Offset(0, 1), // Start from bottom
      end: Offset(0, 0), // End at original position
    ).animate(
      CurvedAnimation(
        parent: _firstContainerController,
        curve: Curves.easeOutBack,
      ),
    );

    _firstContainerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _firstContainerController, curve: Curves.easeIn),
    );

    // Second container animations
    _secondContainerSlide = Tween<Offset>(
      begin: Offset(0, 1), // Start from bottom
      end: Offset(0, 0), // End at original position
    ).animate(
      CurvedAnimation(
        parent: _secondContainerController,
        curve: Curves.easeOutBack,
      ),
    );

    _secondContainerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _secondContainerController, curve: Curves.easeIn),
    );

    Future.delayed(Duration(milliseconds: 800), () {
      setState(() {
        logoLeft = -100;
      });

      Future.delayed(Duration(seconds: 1), () async {
        setState(() {
          showWhiteLogo = true;
        });

        _textController = AnimationController(
          vsync: this,
          duration: Duration(milliseconds: 300),
        );

        // New animations for width expansion and fade-in
        _textWidth = Tween<double>(begin: 0, end: 180).animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

        _textOpacity = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeIn),
        );

        setState(() {
          showTextLogo = true;
        });

        await _textController.forward();

        // Wait for text animation to complete, then animate containers
        await Future.delayed(Duration(milliseconds: 500));
        final user = FirebaseAuth.instance.currentUser?.uid;

        // Show and animate first container

        // Optional: Navigate after all animations complete
        // await Future.delayed(const Duration(seconds: 2));
        if (user != null) {
          Get.off(() => MainScreenView(), transition: Transition.fade);
        } else {
          setState(() async {
            setState(() {
              showFirstContainer = true;
            });
            await _firstContainerController.forward();

            // Wait a bit, then show and animate second container
            await Future.delayed(Duration(milliseconds: 300));
            setState(() {
              showSecondContainer = true;
            });
            await _secondContainerController.forward();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _firstContainerController.dispose();
    _secondContainerController.dispose();
    super.dispose();
  }

  NotificationServices notificationServices = NotificationServices();
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Wallpp (1).JPG'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Main logo animation in center
            Container(color: appColors.black.withOpacity(.4)),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // White logo container
                  AnimatedPositioned(
                    duration: Duration(seconds: 1),
                    left: screenWidth / 2 - 0.5 + logoLeft,
                    top: screenHeight / 2 - 22.5,
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 1200),
                      child: Hero(
                        tag: 'logoHero',
                        child: Container(
                          width: 45,
                          height: 45,
                          child: Image.asset(
                            showWhiteLogo
                                ? 'assets/images/Group (2).png'
                                : 'assets/images/Group (1).png',
                            key: ValueKey(showWhiteLogo),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Text logo that appears to emerge from the white logo
                  if (showTextLogo)
                    Positioned(
                      left: screenWidth / 2 + logoLeft + 50,
                      top: screenHeight / 2 - 10,
                      child: AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) {
                          return ClipRect(
                            child: SizedBox(
                              width: _textWidth.value,
                              height: 36,
                              child: OverflowBox(
                                alignment: Alignment.centerLeft,
                                maxWidth: 180,
                                child: Opacity(
                                  opacity: _textOpacity.value,
                                  child: Image.asset(
                                    'assets/images/angerDrop.png',
                                    width: 180,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.centerLeft,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // First container that animates from bottom
            if (showFirstContainer)
              Positioned(
                bottom: 0,
                left: 20,
                right: 20,
                child: SlideTransition(
                  position: _firstContainerSlide,
                  child: FadeTransition(
                    opacity: _firstContainerOpacity,
                    child: Container(
                      height: 390.h,
                      child: Center(
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/Feel the beat.png',
                              height: 20.h,
                            ),
                            SizedBox(
                              height: 70,
                              width: 200,
                              child: Center(
                                child: Text(
                                  textAlign: TextAlign.center,
                                  'And share the music that makes your vibe!',
                                  style: appThemes.small,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Second container that animates from bottom
            if (showSecondContainer)
              Positioned(
                bottom: 0,
                left: 20,
                right: 20,
                child: SlideTransition(
                  position: _secondContainerSlide,
                  child: FadeTransition(
                    opacity: _secondContainerOpacity,
                    child: Container(
                      height: 280.h,

                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 80),
                          child: Column(
                            children: [
                              roundButton(
                                text: "Login",
                                backgroundGradient: LinearGradient(
                                  colors: [
                                    Color(0xFF7F00FF),
                                    Color(0xFFE100FF),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderColor: Colors.transparent,
                                textColor: Colors.white,
                                onPressed: () => Get.to(() => SignInView()),
                                // Get access token
                              ),

                              SizedBox(height: 20),
                              roundButton(
                                text: "Sign Up",

                                borderColor: appColors.pink,
                                textColor: Colors.white,
                                onPressed: () => Get.to(() => SignUpView()),
                              ),
                              SizedBox(height: 20),
                              GestureDetector(
                                onTap: () {
                                  Get.dialog(PrivacyPolicy());
                                },
                                child: Text(
                                  'By continuing, you agree to Our Terms of Service and Privacy Policy',
                                  textAlign: TextAlign.center,
                                  style: appThemes.small.copyWith(
                                    color: appColors.textGrey,
                                    fontFamily: 'Sans Bold',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

class SplashScreen2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/images/Wallpp (1).JPG',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.4), // Adjust opacity as needed
          ),
          Positioned(
            bottom: 0,
            child: Container(
              height: 500.h,
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,

                children: [
                  Container(
                    height: ScreenUtil().screenHeight * .1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,

                      children: [
                        Image.asset(
                          'assets/images/Group (1)White.png',
                          width: 50.w,
                          height: 50.h,
                        ),
                        Image.asset(
                          'assets/images/angerDrop.png',
                          height: 35.h,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 80),
                    child: Column(
                      children: [
                        roundButton(
                          text: "Login",
                          backgroundGradient: LinearGradient(
                            colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderColor: Colors.transparent,
                          textColor: Colors.white,
                          onPressed: () => Get.to(() => SignInView()),
                        ),
                        SizedBox(height: 20),
                        roundButton(
                          text: "Sign Up",
                          backgroundGradient: LinearGradient(
                            colors: [Colors.transparent, Colors.transparent],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderColor: appColors.pink,
                          textColor: Colors.white,
                          onPressed: () => Get.to(SignUpView()),
                        ),
                        SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Get.dialog(PrivacyPolicy());
                          },
                          child: Text(
                            'By continuing, you agree to Our Terms of Service and Privacy Policy',
                            textAlign: TextAlign.center,
                            style: appThemes.small.copyWith(
                              color: appColors.textGrey,
                              fontFamily: 'Sans Bold',
                            ),
                          ),
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
}

class IntroSplashScreen extends StatefulWidget {
  @override
  State<IntroSplashScreen> createState() => _IntroSplashScreenState();
}

class _IntroSplashScreenState extends State<IntroSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  late Animation<double> _scale;
  late Animation<double> _fade;
  bool showBackground = false;
  NotificationServices notificationServices = NotificationServices();
  @override
  void initState() {
    super.initState();
    notificationServices.requestNotificationPermission();
    notificationServices.firebaseInit(context);
    notificationServices.setupInteractMessage(context);

    notificationServices.getDeviceToken().then((val) {
      print('=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==');
      print('Device token');
      print(val);
    });

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300), // Increased duration
      vsync: this,
    );

    _rotation = Tween<double>(
      begin: 0,
      end: pi / 1.5, // Full 360° rotation for smoother effect
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    _scale = Tween<double>(
      begin: 1.0,
      end: 2.0, // Increased zoom scale for more dramatic effect
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuad),
    );

    _fade = Tween<double>(
      begin: 1.0,
      end: 0.7, // Slight fade during animation
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
  }

  void _startAnimation() async {
    if (_controller.isAnimating) return;

    // Forward animation: Rotate + Zoom In
    await _controller.forward();

    // Pause at max zoom/rotation
    await Future.delayed(const Duration(milliseconds: 200));

    // Reverse animation: Rotate back + Zoom Out
    setState(() => showBackground = true);

    await _controller.reverse();

    // Show background after zoom out completes
    await Future.delayed(const Duration(milliseconds: 300));

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1200),
        pageBuilder: (_, __, ___) => LogoAnimationScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _startAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            image:
                showBackground
                    ? const DecorationImage(
                      image: AssetImage('assets/images/Wallpp (1).JPG'),
                      fit: BoxFit.cover,
                    )
                    : null,
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, child) {
                return Transform.rotate(
                  angle: _rotation.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Opacity(
                      opacity: _fade.value,
                      child: Hero(
                        tag: 'logoHero',
                        child: Image.asset(
                          'assets/images/Group (1).png',
                          width: 50, // Slightly larger base size
                          height: 50,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
