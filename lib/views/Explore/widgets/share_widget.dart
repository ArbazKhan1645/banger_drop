import 'package:banger_drop/consts/consts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class SharesBottomSheet extends StatelessWidget {
  final String bangerId;

  SharesBottomSheet({super.key, required this.bangerId});

  @override
  Widget build(BuildContext context) {
    // ✅ Move controller initialization here
    final SharesController controller = Get.put(
      SharesController(bangerId: bangerId),
    );

    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.purple,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Text('Shared By', style: appThemes.Medium),
          const SizedBox(height: 10),

          Expanded(
            child: Obx(() {
              final shares = controller.shares;
              if (shares.isEmpty) {
                return const Center(
                  child: Text(
                    'No shares yet',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return ListView.separated(
                itemCount: shares.length,
                separatorBuilder: (_, __) => const SizedBox(),
                itemBuilder: (context, index) {
                  final share = shares[index];
                  final name = share['name'] ?? 'User';
                  final sharedAt = share['sharedAt'];
                  final formattedTime =
                      sharedAt != null
                          ? timeAgoSinceDate(sharedAt.toDate())
                          : '';

                  return ListTile(
                    leading: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: share['userImg'] ?? '',
                        width: 40.w,
                        height: 40.h,
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
                    title: Text(name, style: appThemes.small),
                    subtitle: Text(
                      formattedTime,
                      style: TextStyle(
                        color: appColors.textGrey,
                        fontSize: 10.sp,
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

  /// Format DateTime to `5 min ago`
  String timeAgoSinceDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }
}

class SharesController extends GetxController {
  final String bangerId;

  SharesController({required this.bangerId});

  var shares = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchShares();
  }

  Future<void> fetchShares() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('Bangers')
            .doc(bangerId)
            .get();
    final data = doc.data();
    if (data != null && data['shares'] != null) {
      shares.value = List<Map<String, dynamic>>.from(data['shares']);
    }
  }
}
