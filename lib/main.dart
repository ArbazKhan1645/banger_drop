import 'package:audio_service/audio_service.dart';
import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/firebase_options.dart';
import 'package:banger_drop/helper/audio_handler.dart';
import 'package:banger_drop/helper/shared_prefrences_helper.dart';
import 'package:banger_drop/views/chat/controller/contacts_controller.dart';
import 'package:banger_drop/views/single_audio_player/controller/single_audio_controller.dart';
import 'package:banger_drop/views/spalsh/spalsh_screen.dart';
import 'package:banger_drop/views/widgets/bottom_navigation_bar/bottonBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

late MyAudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ✅ Initialize Firebase first
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Then activate Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider:
        AndroidProvider.playIntegrity, // Use PlayIntegrity for production
    appleProvider: AppleProvider.debug,
  );

  // ✅ Setup background messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize local storage, Firestore settings, etc.
  await SharedPreferencesHelper.init();

  FirebaseFirestore.instance.settings = const Settings(
    host: 'firestore.googleapis.com',
    sslEnabled: true,
    persistenceEnabled: true,
  );

  await AppConstants.initializeUserData();

  Get.put(BottomNavController());
  Get.put(SingleBangerPlayerController(), permanent: true);

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    WidgetsBinding.instance.addObserver(LifecycleManager(user.uid));
  }

  // Initialize audio handler (commented)
  // audioHandler = await AudioService.init(...);

  runApp(const MyApp());
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print(message.notification!.title.toString());
}

Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder:
          (_, child) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: GetMaterialApp(
              title: 'Flutter Demo',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              ),
              home: IntroSplashScreen(),
            ),
          ),
      designSize: const Size(390, 884),
      minTextAdapt: true,
      splitScreenMode: true,
    );
  }
}

class LifecycleManager extends WidgetsBindingObserver {
  final String userId;

  LifecycleManager(this.userId);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isOnline = state == AppLifecycleState.resumed;
    FirebaseFirestore.instance.collection('users').doc(userId).set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
