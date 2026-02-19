import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool social = true;
  bool followUp = true;
  bool messages = true;
  bool system = true;

  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    loadPreferencesFromFirestore();
  }

  Future<void> loadPreferencesFromFirestore() async {
    final doc = await firestore.collection('users').doc(uid).get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      setState(() {
        social = data['social'] ?? true;
        followUp = data['followUp'] ?? true;
        messages = data['messages'] ?? true;
        system = data['system'] ?? true;
      });
    } else {
      // If no data exists, initialize defaults in Firestore
      await firestore.collection('users').doc(uid).set({
        'social': true,
        'followUp': true,
        'messages': true,
        'system': true,
      }, SetOptions(merge: true));
    }
  }

  Future<void> updatePreference(String key, bool value) async {
    await firestore.collection('users').doc(uid).set({
      key: value,
    }, SetOptions(merge: true));
  }

  Widget buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withOpacity(0.05),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFDA1DD1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.purpleAccent,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF150024),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(Icons.close, color: Colors.white),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            buildToggleTile(
              title: 'Social',
              subtitle: 'Likes, comments, share',
              value: social,
              onChanged: (val) {
                setState(() => social = val);
                updatePreference('social', val);
              },
            ),
            buildToggleTile(
              title: 'Follow Up Request',
              subtitle: 'Get notified when someone follows you or follows back',
              value: followUp,
              onChanged: (val) {
                setState(() => followUp = val);
                updatePreference('followUp', val);
              },
            ),
            buildToggleTile(
              title: 'Messages',
              subtitle: 'New messages, friend requests',
              value: messages,
              onChanged: (val) {
                setState(() => messages = val);
                updatePreference('messages', val);
              },
            ),
            buildToggleTile(
              title: 'System',
              subtitle: 'Major updates, security alerts',
              value: system,
              onChanged: (val) {
                setState(() => system = val);
                updatePreference('system', val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
