import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfidentialityController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RxBool restrictedProfile = false.obs;
  RxBool restrictedInbox = false.obs;
  RxBool isLoading = true.obs;

  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    isLoading.value = true;
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        restrictedProfile.value = data['restrictedProfile'] ?? false;
        restrictedInbox.value = data['restrictedInbox'] ?? false;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('restrictedProfile', restrictedProfile.value);
        await prefs.setBool('restrictedInbox', restrictedInbox.value);
      }
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateSetting(String field, bool value) async {
    try {
      await _firestore.collection('users').doc(userId).update({field: value});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(field, value);

      if (field == 'restrictedProfile') {
        restrictedProfile.value = value;
      } else if (field == 'restrictedInbox') {
        restrictedInbox.value = value;
      }

      Get.snackbar('Updated', '$field updated to $value');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update $field');
    }
  }
}
