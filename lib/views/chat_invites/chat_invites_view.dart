import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/chat_invites/controller/chat_invites_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class InvitesView extends StatelessWidget {
  final controller = Get.put(InvitesController());

  InvitesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.black,
      body: Column(
        children: [
          // // Back button
          // Padding(
          //   padding: const EdgeInsets.only(left: 16, top: 8),
          //   child: Row(
          //     children: [
          //       GestureDetector(
          //         onTap: () => Get.back(),
          //         child: Container(
          //           padding: const EdgeInsets.all(8),
          //           // decoration: BoxDecoration(
          //           //   color: Colors.black.withOpacity(0.4),
          //           //   shape: BoxShape.circle,
          //           // ),
          //           child: const Icon(Icons.arrow_back, color: Colors.white),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          // Main content
          Expanded(
            child: Stack(
              children: [
                // Background image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/Picture1.png',
                    fit: BoxFit.cover,
                  ),
                ),

                // Overlay
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.2)),
                ),

                // Invite List
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Column(
                    children: [
                      // Back button
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back,
                                color: appColors.white,
                              ),
                              onPressed:
                                  () => Get.back(), // or Navigator.pop(context)
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Expanded(
                        child: Obx(() {
                          if (controller.isLoading.value) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (controller.invites.isEmpty) {
                            return Center(
                              child: Text(
                                'No invites.',
                                style: appThemes.small,
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: EdgeInsets.symmetric(
                              vertical: 16.h,
                              horizontal: 16.w,
                            ),
                            itemCount: controller.invites.length,
                            itemBuilder: (context, index) {
                              final invite = controller.invites[index];
                              final chatId = controller.buildChatId(
                                controller.currentUserId,
                                invite['uid'],
                              );

                              return Card(
                                color: Colors.transparent,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.grey[300],
                                    child: ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: invite['img'],
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        placeholder:
                                            (context, url) =>
                                                const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                        errorWidget:
                                            (context, url, error) => const Icon(
                                              Icons.person,
                                              color: Colors.black,
                                            ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    invite['name'] ?? 'Unknown',
                                    style: appThemes.Medium,
                                  ),
                                  subtitle: Text(
                                    'Sent: ${_getTimeAgo(invite['sentAt'])}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                        onPressed:
                                            () =>
                                                controller.acceptInvite(chatId),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.cancel,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () =>
                                                controller.rejectInvite(chatId),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Converts a Firebase timestamp into human-readable "time ago" format
  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    return '${diff.inDays} days ago';
  }
}
