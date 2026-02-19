import 'dart:io';
import 'dart:math';

import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/new_notification.dart';
import 'package:banger_drop/views/Notification/notification_view.dart';
import 'package:banger_drop/views/chat/chat_view.dart';
import 'package:banger_drop/views/settings/widgets/account_view.dart';
import 'package:banger_drop/views/spalsh/spalsh_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get/instance_manager.dart';

class NotificationServices {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Request permission for iOS
  void requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User denied permission');
    }
  }

  /// Get FCM device token
  Future<String?> getDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      print("FCM Token: $token");
      return token;
    } catch (e) {
      print("Error fetching FCM token: $e");
      return null;
    }
  }

  /// Listen for token refresh
  void isTokenRefresh() {
    messaging.onTokenRefresh.listen((newToken) {
      debugPrint('Token refreshed: $newToken');
    });
  }

  /// Initialize local notifications
  void initLocalNotifications(
    BuildContext context,
    RemoteMessage message,
  ) async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_notification'); // Use your icon here

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        handleMessage(context, message);
      },
    );
  }

  /// Initialize Firebase message listener
  void firebaseInit(BuildContext context) {
    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        debugPrint("Title: ${message.notification?.title}");
        debugPrint("Body: ${message.notification?.body}");
      }
      if (Platform.isAndroid) {
        initLocalNotifications(context, message);
      }
      showNotifications(message);
    });
  }

  /// Show notification using flutter_local_notifications
  Future<void> showNotifications(RemoteMessage message) async {
    final AndroidNotificationChannel channel = const AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );
    final BigPictureStyleInformation bigPictureStyle =
        BigPictureStyleInformation(
          DrawableResourceAndroidBitmap(
            'large_image',
          ), // 👈 name of your image in res/drawable
          contentTitle: message.notification?.title ?? '',
          summaryText: message.notification?.body ?? '',
        );
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          icon: 'ic_notification', // Make sure this exists in res/drawable-*
          styleInformation: bigPictureStyle, // 👈 Use here
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique ID
      message.notification?.title ?? '',
      message.notification?.body ?? '',
      notificationDetails,
    );
  }

  //handles on tap
  Future<void> handleMessage(
    BuildContext context,
    RemoteMessage message,
  ) async {
    bool isLoggedIn = await AppConstants.checkUserLoginStatus();

    if (message.data['type'] == 'social') {
      if (isLoggedIn) {
        Get.to(() => NotificationView());
      } else {
        Get.to(() => IntroSplashScreen());
      }
    } else if (message.data['type'] == 'chat') {
      if (isLoggedIn) {
        Get.to(
          () => ChatScreen(
            imgUrl: message.data['img'],
            name: message.data['name'],
            userId: message.data['uid'],
          ),
        );
      } else {
        Get.to(() => IntroSplashScreen());
      }
    } else if (message.data['type'] == 'follow_request') {
      if (isLoggedIn) {
        Get.to(() => NewNotificationScreen());
      } else {
        Get.to(() => IntroSplashScreen());
      }
    }
  }

  Future<void> setupInteractMessage(BuildContext context) async {
    // when app is terminated
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      handleMessage(context, initialMessage);
    }

    // when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      handleMessage(context, event);
    });
  }
}
