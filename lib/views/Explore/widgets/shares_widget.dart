import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:banger_drop/consts/consts.dart';

class SharesController extends GetxController {
  var sharedUsers =
      <Share>[
        Share(username: 'DJMike', time: '1 min ago'),
        Share(username: 'SoundWave23', time: '4 min ago'),
        Share(username: 'LoFiGirl', time: '12 min ago'),
        Share(username: 'PartyBeats', time: '25 min ago'),
        Share(username: 'MelodyQueen', time: '30 min ago'),
      ].obs;
}

class Share {
  final String username;
  final String time;

  Share({required this.username, required this.time});
}

class SharesBottomSheet extends StatelessWidget {
  SharesBottomSheet({Key? key}) : super(key: key);

  final SharesController controller = Get.put(SharesController());

  @override
  Widget build(BuildContext context) {
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
          Text('Shares', style: appThemes.Medium),
          const SizedBox(height: 10),

          Expanded(
            child: Obx(() {
              return ListView.separated(
                itemCount: controller.sharedUsers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final user = controller.sharedUsers[index];
                  return ListTile(
                    leading: const Icon(Icons.share, color: Colors.white),
                    title: Text(user.username, style: appThemes.small),
                    subtitle: Text(
                      user.time,
                      style: appThemes.small.copyWith(
                        color: Colors.grey[300],
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
