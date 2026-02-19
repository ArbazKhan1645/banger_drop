import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:banger_drop/consts/consts.dart'; // make sure you import your theme/colors

class LikesController extends GetxController {
  var likedUsers = <Like>[].obs;

  void setLikes(List<Map<String, dynamic>> likeMaps) {
    likedUsers.value = likeMaps.map((e) => Like.fromMap(e)).toList();
  }
}

class LikesBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> likeMaps;

  LikesBottomSheet({Key? key, required this.likeMaps}) : super(key: key);

  final LikesController controller = Get.put(LikesController());

  @override
  Widget build(BuildContext context) {
    controller.setLikes(likeMaps);

    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.purple,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Likes', style: appThemes.Medium),
          const SizedBox(height: 10),
          Expanded(
            child: Obx(() {
              return ListView.separated(
                itemCount: controller.likedUsers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final user = controller.likedUsers[index];
                  return ListTile(
                    leading: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl:
                            user.profileImage ?? '', // empty string if null
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const CircleAvatar(
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                        errorWidget:
                            (context, url, error) => const CircleAvatar(
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                      ),
                    ),
                    title: Text(user.username, style: appThemes.small),
                    subtitle: Text(
                      user.time,
                      style: appThemes.small.copyWith(
                        color: appColors.textGrey,
                        fontFamily: 'Sans',
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class Like {
  final String username;
  final String time;
  final String? profileImage;

  Like({required this.username, required this.time, this.profileImage});

  factory Like.fromMap(Map<String, dynamic> map) {
    String formattedTime = 'Just now';

    try {
      final timestamp = DateTime.parse(map['time']);
      final difference = DateTime.now().difference(timestamp);

      if (difference.inMinutes < 1) {
        formattedTime = 'Just now';
      } else if (difference.inMinutes < 60) {
        formattedTime = '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        formattedTime = '${difference.inHours} hr ago';
      } else {
        formattedTime = '${difference.inDays} d ago';
      }
    } catch (_) {}

    return Like(
      username: map['name'] ?? 'Unknown',
      profileImage: map['img'], // nullable
      time: formattedTime,
    );
  }
}
