import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/leaderboard/controller/leaderboard_controller.dart';
import 'package:banger_drop/views/leaderboard/widgets/leaderboard_top_widget.dart';
import 'package:banger_drop/views/leaderboard/widgets/leaderboard_widget.dart';
import 'package:banger_drop/views/leaderboard/widgets/listitem_widget.dart';
import 'package:banger_drop/views/leaderboard/widgets/ranking_info.dart';
import 'package:banger_drop/views/leaderboard/widgets/tabselector_widget.dart';
import 'package:banger_drop/views/artist_profile/artist_profile_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({super.key});

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  final controller = Get.put(LeaderboardController());

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/images/Picture1.png',
                ), // Replace with your image path
                fit: BoxFit.cover,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 50),
                  LeaderboardTopWidget(
                    infoTap: () {
                      Get.dialog(RankingInfoDialog());
                    },
                  ),
                  // TabSelector(),
                  buildTimeFilterTabs(),

                  Obx(
                    () => LeaderboardWidget(
                      filter: controller.selectedFilter.value,
                    ),
                  ),
                  Obx(() {
                    return ListView.builder(
                      itemCount: controller.leaderboard.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final user = controller.leaderboard[index];

                        return LeaderboardListItem(
                          onTap: () {
                            Get.to(
                              () =>
                                  ArtistProfileView(userId: user['uid'] ?? ''),
                            );
                            // You can pass user ID if needed
                          },
                          rank: index + 4, // Since these are users AFTER top 3
                          name: user['username'],
                          points: user['points'],
                          imageUrl: user['profileImage'],
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTimeFilterTabs() {
    final List<TimeFilter> customOrder = [
      TimeFilter.AllTime,
      TimeFilter.Daily,
      TimeFilter.Weekly,
      TimeFilter.Monthly,
    ];

    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children:
              customOrder.map((filter) {
                final isSelected = controller.selectedFilter.value == filter;

                return GestureDetector(
                  onTap: () => controller.changeFilter(filter),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          filter.name.replaceAll('_', ' '),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 2,
                          width: 20,
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.purpleAccent
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
