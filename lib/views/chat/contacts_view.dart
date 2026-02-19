import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/story/story_view.dart';
import 'package:banger_drop/views/Explore/widgets/search_textfield.dart';
import 'package:banger_drop/views/artist_profile/artist_profile_view.dart';
import 'package:banger_drop/views/chat/chat_view.dart';
import 'package:banger_drop/views/chat/controller/contacts_controller.dart';
import 'package:banger_drop/views/chat/widgets/contact_widget.dart';
import 'package:banger_drop/views/chat/widgets/stories_widget.dart';
import 'package:banger_drop/views/chat_invites/chat_invites_view.dart';
import 'package:banger_drop/views/widgets/loading_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ContactsView extends StatefulWidget {
  const ContactsView({super.key});

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  final controller = Get.put(ContactsController());

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/Picture1.png', fit: BoxFit.cover),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Inbox',
                      style: appThemes.Large.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.to(() => InvitesView()),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Base Text
                          Text(
                            'Invites',
                            style: appThemes.Medium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          // Badge on top-right
                          Obx(() {
                            final count = controller.inviteCount.value;
                            if (count == 0) return const SizedBox.shrink();

                            return Positioned(
                              top: -15,
                              right: -8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Center(
                                  child: Text(
                                    count > 99 ? '99+' : '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Obx(
                  () => SearchBarWidget(
                    controller: controller.searchController.value,
                    hint: 'Search',
                    onChanged:
                        (value) =>
                            controller.searchQuery.value = value.toLowerCase(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 115.h,
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('users')
                            .snapshots(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) return const SizedBox();

                      final currentUserId = controller.currentUserId;
                      final allUsers =
                          userSnapshot.data!.docs
                              .where((doc) => doc.id != currentUserId)
                              .toList();

                      return FutureBuilder<QuerySnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('stories')
                                .get(),
                        builder: (context, storySnapshot) {
                          if (storySnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return LoadingWidget(color: appColors.white);
                          }

                          if (!storySnapshot.hasData) return const SizedBox();

                          final storyDocs = storySnapshot.data!.docs;
                          final storyMap = {
                            for (var doc in storyDocs)
                              doc.id: doc.data() as Map<String, dynamic>,
                          };

                          final usersWithStory = <QueryDocumentSnapshot>[];
                          final usersWithoutStory = <QueryDocumentSnapshot>[];

                          for (var user in allUsers) {
                            if (storyMap.containsKey(user.id)) {
                              usersWithStory.add(user);
                            } else {
                              usersWithoutStory.add(user);
                            }
                          }

                          final sortedUsers = [
                            ...usersWithStory,
                            ...usersWithoutStory,
                          ];

                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: sortedUsers.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Obx(() {
                                  if (controller.hasMyStory.value &&
                                      controller.myStoryData.value != null) {
                                    final story = controller.myStoryData.value!;
                                    return GestureDetector(
                                      onTap: () {
                                        Get.to(
                                          () => StoryViewer(
                                            type: story['type'],
                                            url: story['url'],
                                            userImage: story['img'] ?? '',
                                            userName: story['name'] ?? 'User',
                                          ),
                                        );
                                      },
                                      child: UserProfileWidget(
                                        imageUrl: story['img'] ?? '',
                                        name: 'My Story',
                                        isOnline: false,
                                      ),
                                    );
                                  } else {
                                    return Obx(() {
                                      if (controller.isUploadingStory.value) {
                                        return Column(
                                          children: [
                                            SizedBox(
                                              width: 70.w,
                                              height: 70.h,
                                              child: LoadingWidget(
                                                color: appColors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            SizedBox(
                                              width: 80,
                                              child: Text(
                                                'Uploading...',
                                                textAlign: TextAlign.center,
                                                style: appThemes.small.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                      return GestureDetector(
                                        onTap:
                                            () => controller.pickAndUploadStory(
                                              context,
                                            ),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 70.w,
                                              height: 70.h,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.grey,
                                                  width: 2,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.add,
                                                size: 35,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            SizedBox(
                                              width: 80,
                                              child: Text(
                                                'Add Story',
                                                textAlign: TextAlign.center,
                                                style: appThemes.small.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    });
                                  }
                                });
                              }

                              final userDoc = sortedUsers[index - 1];
                              final userData =
                                  userDoc.data() as Map<String, dynamic>;
                              final uid = userDoc.id;
                              final hasStory = storyMap.containsKey(uid);

                              return GestureDetector(
                                onTap:
                                    hasStory
                                        ? () => controller.viewUserStory(uid)
                                        : null,
                                child: UserProfileWidget(
                                  imageUrl: userData['img'] ?? '',
                                  name: userData['name'] ?? 'User',
                                  isOnline: userData['isOnline'] ?? false,
                                  dimmed: !hasStory,
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),

                Obx(() {
                  final query = controller.searchQuery.value;
                  final stream =
                      query.isEmpty
                          ? controller.getChatUsersStream()
                          : controller.getAllUsersForSearch();

                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: stream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final filtered =
                          snapshot.data!.where((user) {
                            final name = (user['name'] ?? '').toLowerCase();
                            return name.contains(query);
                          }).toList();
                      final uniqueUsers = <String, Map<String, dynamic>>{};
                      for (var user in filtered) {
                        uniqueUsers[user['uid']] =
                            user; // This will override duplicates
                      }
                      final finalList = uniqueUsers.values.toList();

                      if (finalList.isEmpty) {
                        return Center(
                          child: Column(
                            // mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 50.h),
                              Icon(
                                Icons.add_box_rounded,
                                color: appColors.pink,
                                size: 50.sp,
                              ),
                              Text(
                                'Search Users to Chat',
                                style: appThemes.small.copyWith(),
                              ),
                            ],
                          ),
                        );
                      }

                      return Expanded(
                        child: ListView.builder(
                          itemCount: finalList.length,
                          itemBuilder: (context, index) {
                            final user = finalList[index];
                            final otherUserId = user['uid'];
                            final chatId = controller.generateChatId(
                              controller.currentUserId,
                              otherUserId,
                            );

                            return StreamBuilder<QuerySnapshot>(
                              stream:
                                  FirebaseFirestore.instance
                                      .collection('chats')
                                      .doc(chatId)
                                      .collection('messages')
                                      .where(
                                        'senderId',
                                        isNotEqualTo: controller.currentUserId,
                                      )
                                      .snapshots(),
                              builder: (context, snapshot) {
                                int unreadCount = 0;

                                if (snapshot.hasData) {
                                  for (var doc in snapshot.data!.docs) {
                                    final isReadBy = List<String>.from(
                                      doc['isReadBy'] ?? [],
                                    );
                                    if (!isReadBy.contains(
                                      controller.currentUserId,
                                    )) {
                                      unreadCount++;
                                    }
                                  }
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3,
                                  ),
                                  child: MessageTile(
                                    profileTap: () {
                                      Get.to(
                                        () => ArtistProfileView(
                                          userId: otherUserId,
                                        ),
                                      );
                                    },
                                    ontap:
                                        () => Get.to(
                                          () => ChatScreen(
                                            userId: otherUserId,
                                            name: user['name'] ?? '***',
                                            imgUrl: user['img'] ?? '',
                                          ),
                                        ),
                                    imageUrl: user['img'] ?? '',
                                    name: user['name'] ?? 'Unknown',
                                    messageSummary:
                                        user['lastMessage'] ?? 'Start a chat',
                                    time: _getTimeAgo(user['lastMessageTime']),
                                    online: unreadCount > 0, // ✅ now realtime!
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null || timestamp is! Timestamp) return '';
    final dt = timestamp.toDate();
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} hrs';
    return '${diff.inDays} days';
  }
}
