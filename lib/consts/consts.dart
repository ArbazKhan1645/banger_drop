import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class appColors {
  static Color pink = Color(0xffC22BB7);
  static Color black = Color(0xff000000);
  static Color white = Color(0xffFFFFFF);
  static Color textGrey = Color(0xffA5A5A5);
  static Color purple = Color(0xFF4B0082);
  static Color red = Colors.red;
}

class appThemes {
  static TextStyle small = TextStyle(
    fontSize: 13.sp,
    color: Colors.white,
    fontFamily: 'Sans Bold',
  );

  static TextStyle Medium = TextStyle(
    fontSize: 16.sp,
    color: Colors.white,
    fontFamily: 'Sans Bold',
  );

  static TextStyle Large = TextStyle(
    fontSize: 20.sp,
    color: Colors.white,
    fontFamily: 'Sans Bold',
  );
}

class AppConstants {
  static const String appUrl = 'https://gfblndvborkjfrsvvnvj.supabase.co';
  static const String appKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'; // trimmed

  static String userName = '';
  static String email = '';
  static String userId = '';
  static String userImg = '';
  static String points = '';

  /// Call this once after login to fetch and store user data
  static Future<void> initializeUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User is not logged in');
      return;
    }

    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (docSnapshot.exists) {
        userName = docSnapshot.data()?['name'] ?? '';
        email = docSnapshot.data()?['email'] ?? '';
        userImg = docSnapshot.data()?['img'] ?? '';
        points = docSnapshot.data()?['points'].toString() ?? '0';
        userId = user.uid.toString();
        print('User data fetched: $userName - $email');
      } else {
        print('User document does not exist');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  static Future<bool> checkUserLoginStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    return user != null;
  }
}
