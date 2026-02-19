import 'dart:convert';
import 'package:banger_drop/notifications/get_serverKey.dart';
import 'package:banger_drop/notifications/notifications_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class FcmNotificationSender {
  final NotificationServices _notificationServices = NotificationServices();
  final GetServerKey _getServerKey = GetServerKey();
  Future<void> sendNotification({
    required String title,
    required String body,
    required String? targetToken,
    Map<String, String>? dataPayload,
    String? uid, // target user's UID for token removal if unregistered
  }) async {
    if (targetToken == null || targetToken.isEmpty) {
      print('❌ Target device token not found.');
      return;
    }

    // 🛑 Get current user's device token to prevent self-notification
    final currentUserToken = await NotificationServices().getDeviceToken();

    if (targetToken == currentUserToken) {
      print('🚫 Skipping notification to self.');
      return;
    }

    try {
      String accessToken = await _getServerKey.getsServerKeyToken();

      var payload = {
        "message": {
          "token": targetToken,
          "notification": {"title": title, "body": body},
          "data": dataPayload ?? {},
        },
      };

      final response = await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/bangerdrop-aaed4/messages:send',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      print('📤 Status: ${response.statusCode}');
      print('📤 Response body: ${response.body}');

      // 🔁 Handle invalid/unregistered token
      if (response.statusCode == 404) {
        final resBody = jsonDecode(response.body);
        final errorCode = resBody['error']?['details']?[0]?['errorCode'];

        if (errorCode == "UNREGISTERED") {
          print('❌ Token is unregistered. Removing from Firestore...');
          if (uid != null) {
            await removeFcmTokenFromUser(uid, targetToken);
          }
        }
      }
    } catch (e) {
      print('❗ Notification send failed: $e');
    }
  }

  Future<void> removeFcmTokenFromUser(String uid, String tokenToRemove) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    await userRef.update({
      'fcmTokens': FieldValue.arrayRemove([tokenToRemove]),
    });

    print('🧹 Token removed from Firestore.');
  }

  Future<List<String>> fetchFcmTokensForUser(String uid) async {
    try {
      final docSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (docSnapshot.exists) {
        List<dynamic>? tokens = docSnapshot.data()?['fcmTokens'];
        if (tokens != null && tokens.isNotEmpty) {
          return tokens.cast<String>();
        }
      }
      return [];
    } catch (e) {
      print('❗ Error fetching tokens for user $uid: $e');
      return [];
    }
  }
}
