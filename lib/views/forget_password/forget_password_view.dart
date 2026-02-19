import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/widgets/buttons.dart';
import 'package:banger_drop/views/widgets/textfiled_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({Key? key}) : super(key: key);

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> changePassword() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      showError('No user is signed in.');
      return;
    }

    if (newPasswordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      showError('New passwords do not match.');
      return;
    }

    setState(() => isLoading = true);

    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: oldPasswordController.text.trim(),
    );

    try {
      // Re-authenticate
      await user.reauthenticateWithCredential(cred);

      // Update password
      await user.updatePassword(newPasswordController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String error = 'An error occurred.';
      if (e.code == 'wrong-password') {
        error = 'Old password is incorrect.';
      } else if (e.code == 'weak-password') {
        error = 'New password is too weak.';
      } else if (e.code == 'requires-recent-login') {
        error = 'Please log in again to change your password.';
      }
      showError(error);
    } catch (e) {
      showError('Something went wrong. Please try again.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/Picture1.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      const BackButton(color: Colors.white),
                      Text(
                        'Change Password',
                        style: appThemes.Large.copyWith(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  CustomEmailField(
                    controller: oldPasswordController,
                    hintText: 'Old Password',
                    isPassword: true,
                  ),
                  const SizedBox(height: 10),

                  CustomEmailField(
                    controller: newPasswordController,
                    hintText: 'New Password',
                    isPassword: true,
                  ),
                  const SizedBox(height: 10),

                  CustomEmailField(
                    controller: confirmPasswordController,
                    hintText: 'Re-Enter Password',
                    isPassword: true,
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 60.w,
                      vertical: 30,
                    ),
                    child: roundButton(
                      loading: isLoading,
                      text: "Change Password",
                      backgroundGradient: const LinearGradient(
                        colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderColor: appColors.pink,
                      textColor: Colors.white,
                      onPressed: changePassword,
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
