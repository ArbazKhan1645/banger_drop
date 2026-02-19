import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/main.dart';
import 'package:banger_drop/views/auth/controllers/auth_controller.dart';
import 'package:banger_drop/views/prefrences/prefrences.dart';
import 'package:banger_drop/views/utilities/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UsernamePromptScreen extends StatefulWidget {
  final User user;

  const UsernamePromptScreen({super.key, required this.user});

  @override
  State<UsernamePromptScreen> createState() => _UsernamePromptScreenState();
}

class _UsernamePromptScreenState extends State<UsernamePromptScreen>
    with SingleTickerProviderStateMixin {
  final authcontroller = AuthController();
  final TextEditingController usernameController = TextEditingController();
  bool isLoading = false;
  String? errorText;

  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    usernameController.dispose();
    super.dispose();
  }

  Future<bool> isUsernameAvailable(String username) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('usernames')
            .doc(username)
            .get();
    return !doc.exists;
  }

  Future<void> submitUsername() async {
    final username = usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => errorText = 'Username cannot be empty');
      return;
    }

    setState(() {
      isLoading = true;
      errorText = null;
    });

    final available = await isUsernameAvailable(username);
    if (!available) {
      setState(() {
        errorText = 'Username already taken';
        isLoading = false;
      });
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .set({
          'uid': widget.user.uid,
          'username': username,
          'name': widget.user.displayName ?? 'User',
          'email': widget.user.email ?? '',
          'points': 0,
        });

    await FirebaseFirestore.instance.collection('usernames').doc(username).set({
      'uid': widget.user.uid,
      'email': widget.user.email ?? '',
    });

    await authcontroller.saveFcmToken(FirebaseAuth.instance.currentUser!.uid);

    AppConstants.initializeUserData();
    WidgetsBinding.instance.addObserver(LifecycleManager(widget.user.uid));

    Utilities.successMessege('Success', 'Welcome, $username!');
    Get.offAll(() => Prefrences(fromSettings: false));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeIn,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Image.asset('assets/images/Group (2).png')],
                ),
                const SizedBox(height: 50),
                Text(
                  "Choose a Unique Username",
                  style: appThemes.small.copyWith(fontFamily: 'Sans'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Enter username",
                    hintStyle: const TextStyle(color: Colors.white54),
                    errorText: errorText,
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isLoading ? null : submitUsername,
                    child:
                        isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : Text("Continue", style: appThemes.Medium),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
