import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/notifications/fcm_notification_sender.dart';
import 'package:banger_drop/views/chat/controller/chat_controller.dart';
import 'package:banger_drop/views/widgets/share_audio_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

void showPlaylistShareBottomSheet({
  required String playlistId,
  required String title,
  required String? imageUrl,
}) {
  final controller = Get.put(AudioShareController()); // reuse this controller
  final FcmNotificationSender sender = FcmNotificationSender();

  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SizedBox(
        height: ScreenUtil().screenHeight * .5,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Send Playlist To...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.users.length,
                  itemBuilder: (_, index) {
                    final user = controller.users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            user['img'].isNotEmpty
                                ? NetworkImage(user['img'])
                                : null,
                        child:
                            user['img'].isEmpty
                                ? const Icon(Icons.person)
                                : null,
                      ),
                      title: Text(user['name']),
                      onTap: () async {
                        final chatController = Get.put(ChatController());
                        chatController.sendPlaylistMessage(
                          receiverId: user['id'],
                          playlistId: playlistId,
                          title: title,
                          imageUrl: imageUrl,
                        );
                        Get.back();
                        final targetToken = await sender.fetchFcmTokensForUser(
                          user['id'],
                        );

                        for (String token in targetToken) {
                          await sender.sendNotification(
                            title: "Playlist shared",
                            body:
                                "${AppConstants.userName} shared your Playlist",
                            targetToken: token,
                            dataPayload: {"type": "social"},
                            uid: user['id'],
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    ),
    isScrollControlled: true,
  );
}
