// ✅ FINAL AuthController with FCM token integration across all auth methods

import 'dart:convert';
import 'dart:math';
import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/main.dart';
import 'package:banger_drop/notifications/notifications_services.dart';
import 'package:banger_drop/views/chat/controller/contacts_controller.dart';
import 'package:banger_drop/views/prefrences/prefrences.dart';
import 'package:banger_drop/views/username/username_view.dart';
import 'package:banger_drop/views/widgets/bottom_navigation_bar/bottonBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthController extends GetxController {
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final NotificationServices _notificationServices = NotificationServices();

  var emailController = TextEditingController().obs;
  var nameController = TextEditingController().obs;
  var passController = TextEditingController().obs;
  var ConfirmPassController = TextEditingController().obs;
  var usernameController = TextEditingController().obs;
  final isLoading = false.obs;

  void showFancySnackbar(String title, String message, {Color? background}) {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: background ?? Colors.red.shade600,
        elevation: 6,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(
              background == Colors.green
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> isUsernameTaken(String username) async {
    final doc = await db.collection('usernames').doc(username).get();
    return doc.exists;
  }

  // Future<void> saveFcmToken(String uid) async {
  //   try {
  //     final token = await _notificationServices.getDeviceToken();
  //     print('📦 Token to save: $token for uid: $uid');

  //     if (token != null) {
  //       final docRef = db.collection('users').doc(uid);
  //       final snapshot = await docRef.get();

  //       if (snapshot.exists) {
  //         final List<dynamic> existingTokens =
  //             snapshot.data()?['fcmTokens'] ?? [];
  //         if (!existingTokens.contains(token)) {
  //           await docRef.update({
  //             'fcmTokens': FieldValue.arrayUnion([token]),
  //           });
  //           print("✅ Token saved to Firestore");
  //         } else {
  //           print("ℹ️ Token already exists in Firestore");
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     print('❌ Error saving FCM token: $e');
  //   }
  // }

  Future<void> saveFcmToken(String uid) async {
    try {
      final token = await _notificationServices.getDeviceToken();
      if (token == null) return;

      final docRef = db.collection('users').doc(uid);
      final snapshot = await docRef.get();
      if (!snapshot.exists) return;

      final List<dynamic> existingTokens = snapshot.data()?['fcmTokens'] ?? [];
      final List<dynamic> devices = snapshot.data()?['devices'] ?? [];

      // Get current device info
      final deviceInfo = DeviceInfoPlugin();
      String deviceName = "Unknown Device";
      String platform = Platform.operatingSystem;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = "${androidInfo.brand} ${androidInfo.model}";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = "${iosInfo.name} ${iosInfo.model}";
      }

      // Build new device entry
      final newDevice = {
        'token': token,
        'deviceName': deviceName,
        'platform': platform,
        'loggedInAt': Timestamp.now(),
      };

      // Update fcmTokens if not already present
      if (!existingTokens.contains(token)) {
        await docRef.update({
          'fcmTokens': FieldValue.arrayUnion([token]),
        });
        print("✅ Token added to fcmTokens");
      } else {
        print("ℹ️ Token already exists in fcmTokens");
      }

      // Update devices list if this token not already recorded
      final tokenExistsInDevices = devices.any(
        (device) => device['token'] == token,
      );
      if (!tokenExistsInDevices) {
        await docRef.update({
          'devices': FieldValue.arrayUnion([newDevice]),
        });
        print("✅ Device info added to devices");
      } else {
        print("ℹ️ Device info already recorded");
      }
    } catch (e) {
      print('❌ Error saving FCM token or device info: $e');
    }
  }

  Future<User?> signUpWithEmailPassword() async {
    isLoading.value = true;
    try {
      final email = emailController.value.text.trim();
      final password = passController.value.text.trim();
      final username = usernameController.value.text.trim();

      if (email.isEmpty || password.isEmpty || username.isEmpty) {
        showFancySnackbar("Error", "Fields cannot be empty");
        return null;
      }

      if (await isUsernameTaken(username)) {
        showFancySnackbar("Error", "Username already taken");
        return null;
      }

      if (password.length < 6) {
        showFancySnackbar("Weak Password", "Minimum 6 characters required");
        return null;
      }

      if (passController.value.text != ConfirmPassController.value.text) {
        showFancySnackbar("Error", "Passwords do not match");
        return null;
      }

      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      await db.collection('users').doc(uid).set({
        'uid': uid,
        'username': username,
        'name': username,
        'email': email,
        'points': 0,
        'authProvider': 'email',
        'fcmTokens': [],
      });

      await db.collection('usernames').doc(username).set({
        'uid': uid,
        'email': email,
      });

      await saveFcmToken(uid);

      showFancySnackbar(
        "Success",
        "Account created successfully",
        background: Colors.green,
      );
      Get.put(ContactsController());
      Get.offAll(() => Prefrences(fromSettings: false));
      WidgetsBinding.instance.addObserver(LifecycleManager(uid));
      AppConstants.initializeUserData();
      return credential.user;
    } catch (e) {
      showFancySnackbar("Sign Up Failed", e.toString());
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithUsernamePassword() async {
    isLoading.value = true;
    try {
      final input = usernameController.value.text.trim();
      final password = passController.value.text.trim();

      if (input.isEmpty || password.isEmpty) {
        showFancySnackbar(
          "Error",
          "Username/Email and password cannot be empty",
        );
        return;
      }

      String? uid;
      String? email;

      if (input.contains('@')) {
        final userQuery =
            await db
                .collection('users')
                .where('email', isEqualTo: input)
                .limit(1)
                .get();
        if (userQuery.docs.isEmpty) throw Exception("Email not found");
        final doc = userQuery.docs.first;
        uid = doc['uid'];
        email = input;
      } else {
        final userQuery =
            await db
                .collection('users')
                .where('username', isEqualTo: input)
                .limit(1)
                .get();
        if (userQuery.docs.isEmpty) throw Exception("Username not found");
        final doc = userQuery.docs.first;
        uid = doc['uid'];
        email = doc['email'];
      }

      await auth.signInWithEmailAndPassword(email: email!, password: password);
      await saveFcmToken(uid!);

      showFancySnackbar(
        "Login Success",
        "Welcome back!",
        background: Colors.green,
      );
      Get.offAll(() => MainScreenView());
    } catch (e) {
      showFancySnackbar("Login Failed", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUpWithGoogle(BuildContext context) async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);
      final user = userCredential.user;
      final isNew = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNew && user != null) {
        await handleNewSocialUser(user);
      } else {
        await saveFcmToken(user!.uid).then((val) {
          print(
            '=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-stored fcm to uid : ${user.uid}',
          );
        });
        Get.put(ContactsController());
        Get.offAll(() => MainScreenView());
        showFancySnackbar(
          "Success",
          "Login Successfully",
          background: Colors.green,
        );
        WidgetsBinding.instance.addObserver(LifecycleManager(user.uid));
        AppConstants.initializeUserData();
      }
    } catch (e) {
      showFancySnackbar("Failed", "Google Sign-In failed");
    }
  }

  Future<void> signUpWithFacebook() async {
    try {
      // Request specific permissions
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        throw Exception("Facebook Sign-In Cancelled");
      }

      final accessToken = result.accessToken!;
      final credential = FacebookAuthProvider.credential(
        accessToken.tokenString,
      );

      final userCredential = await auth.signInWithCredential(credential);
      final user = userCredential.user;
      final isNew = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNew && user != null) {
        await handleNewSocialUser(user);
      } else {
        await saveFcmToken(user!.uid);
        Get.put(ContactsController());
        Get.offAll(() => MainScreenView());
        showFancySnackbar(
          "Success",
          "Login Successfully",
          background: Colors.green,
        );
        WidgetsBinding.instance.addObserver(LifecycleManager(user.uid));
        AppConstants.initializeUserData();
      }
    } catch (e) {
      debugPrint('Facebook login error: $e');
      showFancySnackbar("Failure", "Facebook Sign-In failed");
    }
  }

  Future<void> signUpWithApple(BuildContext context) async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider(
        "apple.com",
      ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

      final userCredential = await auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;
      final isNew = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNew && user != null) {
        await handleNewSocialUser(user);
      } else {
        await saveFcmToken(user!.uid);
        Get.put(ContactsController());
        Get.offAll(() => MainScreenView());
        showFancySnackbar(
          "Success",
          "Login Successfully",
          background: Colors.green,
        );
        WidgetsBinding.instance.addObserver(LifecycleManager(user.uid));
        AppConstants.initializeUserData();
      }
    } catch (e) {
      showFancySnackbar("Failed", "Apple Sign-In failed");
    }
  }

  Future<void> handleNewSocialUser(User user) async {
    Get.to(() => UsernamePromptScreen(user: user));
  }

  Future<void> saveNewSocialUsername(User user, String username) async {
    await db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'username': username,
      'email': user.email,
      'name': user.displayName ?? '',
      'points': 0,
      'authProvider': user.providerData.first.providerId,
    }, SetOptions(merge: true));

    await db.collection('usernames').doc(username).set({
      'uid': user.uid,
      'email': user.email,
    });

    // ✅ Ensure permission + token fetch + save after setting username
    await saveFcmToken(user.uid);

    Get.put(ContactsController());
    Get.offAll(() => Prefrences(fromSettings: false));
    WidgetsBinding.instance.addObserver(LifecycleManager(user.uid));
    AppConstants.initializeUserData();
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> deleteUsersWithoutUID() async {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    try {
      final QuerySnapshot snapshot = await db.collection('users').get();

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        if (!data.containsKey('uid')) {
          await db.collection('users').doc(doc.id).delete();
          print('Deleted user document with ID: ${doc.id} (missing uid)');
        }
      }

      print('Cleanup complete.');
    } catch (e) {
      print('Error while deleting documents: $e');
    }
  }
}
