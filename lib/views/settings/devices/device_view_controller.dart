import 'package:banger_drop/consts/consts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class DevicesController extends GetxController {
  final String uid;

  DevicesController(this.uid);

  RxList<Map<String, dynamic>> devices = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    fetchDevices();
    super.onInit();
  }

  void fetchDevices() async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null && data['devices'] != null) {
        devices.value = List<Map<String, dynamic>>.from(data['devices']);
      }
    } catch (e) {
      print('❌ Error fetching devices: $e');
    }
  }

  void removeDevice(String token) async {
    try {
      final updatedDevices = devices.where((d) => d['token'] != token).toList();
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'devices': updatedDevices,
        'fcmTokens': FieldValue.arrayRemove([token]),
      });

      devices.value = updatedDevices;
      Get.snackbar('Success', 'Device removed');
    } catch (e) {
      print('❌ Error removing device: $e');
      Get.snackbar('Error', 'Failed to remove device');
    }
  }

  void logoutAllDevicesExceptCurrent(String currentToken) async {
    try {
      // Filter out all devices except the one with currentToken
      final updatedDevices =
          devices.where((d) => d['token'] == currentToken).toList();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'devices': updatedDevices,
        'fcmTokens': FieldValue.arrayUnion([
          currentToken,
        ]), // ensure current token stays
      });

      devices.value = updatedDevices;
      Get.snackbar('Success', 'Logged out from all other devices');
    } catch (e) {
      print('❌ Error logging out from other devices: $e');
      Get.snackbar('Error', 'Failed to logout other devices');
    }
  }

  void confirmLogoutAllDevices(String token) {
    Get.defaultDialog(
      title: 'Confirm Logout',
      middleText: 'Are you sure you want to logout from all devices?',
      textConfirm: 'Yes',
      textCancel: 'No',
      confirmTextColor: appColors.white,
      onConfirm: () {
        logoutAllDevicesExceptCurrent(token);
        Get.back(); // close dialog
      },
      onCancel: () {
        Get.back(); // just close dialog
      },
    );
  }
}
