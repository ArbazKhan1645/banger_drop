import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/forget_password/forget_password_view.dart';
import 'package:banger_drop/views/settings/widgets/remove_account.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool isEmailPasswordUser = false;
  bool isLoading = true;
  final controller = Get.put(AccountController());
  @override
  void initState() {
    super.initState();
    checkAuthProvider();
  }

  Future<void> checkAuthProvider() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      for (final providerProfile in user.providerData) {
        if (providerProfile.providerId == 'password') {
          setState(() {
            isEmailPasswordUser = true;
          });
          break;
        }
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF150024),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: const Icon(Icons.close, color: Colors.white),
        ),
        actions: [],
        title: const Text('Security', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isEmailPasswordUser) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Get.to(() => ForgetPassword());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDA1DD1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Change password',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    const Text(
                      'Two-factor authentication',
                      style: TextStyle(
                        color: Color(0xFFDA1DD1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Add an extra layer of protection to your online accounts',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => SwitchListTile(
                        title: Text(
                          'Enable 2-Factor Authentication',
                          style: TextStyle(color: Colors.white),
                        ),
                        value: controller.is2FAEnabled.value,
                        onChanged: (value) {
                          controller.toggle2FA(value);
                        },

                        activeColor: Colors.greenAccent,
                      ),
                    ),

                    const Divider(
                      color: Colors.white24,
                      thickness: 1,
                      height: 40,
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(() => DeleteAccountScreen());
                      },
                      child: const Text(
                        'delete account',
                        style: TextStyle(
                          color: Color(0xFFDA1DD1),
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

class AccountController extends GetxController {
  RxBool is2FAEnabled = false.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    fetch2FAStatus();
  }

  void fetch2FAStatus() async {
    final userDoc =
        await _firestore.collection('users').doc(AppConstants.userId).get();
    final data = userDoc.data();
    if (data != null && data.containsKey('twoFA')) {
      is2FAEnabled.value = data['twoFA'] == true;
    }
  }

  void toggle2FA(bool value) async {
    try {
      await _firestore.collection('users').doc(AppConstants.userId).update({
        'twoFA': value,
      });
      is2FAEnabled.value = value;

      Get.snackbar("Success", value ? "2FA Enabled" : "2FA Disabled");
    } catch (e) {
      Get.snackbar("Error", "Failed to update 2FA status: $e");
    }
  }
}
