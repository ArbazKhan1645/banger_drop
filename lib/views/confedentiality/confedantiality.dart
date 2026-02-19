import 'package:banger_drop/views/confedentiality/controller/confedentiality_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConfedentialitySetting extends StatelessWidget {
  const ConfedentialitySetting({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ConfidentialityController());

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
          'Confidentiality',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Obx(
        () =>
            controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      buildToggleTile(
                        title: 'Restricted profile',
                        subtitle:
                            'Only people who you have approved as followers can see your profile details, posts, and other content',
                        value: controller.restrictedProfile.value,
                        onChanged:
                            (val) => controller.updateSetting(
                              'restrictedProfile',
                              val,
                            ),
                      ),
                      buildToggleTile(
                        title: 'Restricted inbox',
                        subtitle:
                            'Only people who you have approved as followers can chat with you ',
                        value: controller.restrictedInbox.value,
                        onChanged:
                            (val) => controller.updateSetting(
                              'restrictedInbox',
                              val,
                            ),
                      ),
                    ],
                  ),
                ),
      ),
    );
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
}
