import 'package:banger_drop/main.dart';
import 'package:banger_drop/views/chat/controller/contacts_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:ui';

// --- Replace with your actual imports
import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/Explore/explore_view.dart';
import 'package:banger_drop/views/add_banger/add_view.dart';
import 'package:banger_drop/views/chat/contacts_view.dart';
import 'package:banger_drop/views/leaderboard/leaderboard_view.dart';
import 'package:banger_drop/views/profile/profile_view.dart';

// ------------ NAV ITEM DATA ------------
class _NavItemData {
  final String imagePath;
  final String label;

  const _NavItemData({required this.imagePath, required this.label});
}

// ------------ CONTROLLER ------------
class BottomNavController extends GetxController {
  var selectedIndex = 0.obs;
  final PageController pageController = PageController();

  var overlayStack = <Widget>[].obs;
  @override
  void onInit() {
    // TODO: implement onInit

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      WidgetsBinding.instance.addObserver(LifecycleManager(user.uid));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.context != null) {
          // Get.snackbar(
          //   'Error',
          //   'User not online. Please restart the app.',
          //   snackPosition: SnackPosition.BOTTOM,
          // );
        }
      });
    }

    super.onInit();
  }

  void changeIndex(int index) {
    selectedIndex.value = index;
    pageController.jumpToPage(index);
    clearOverlays();
  }

  void pushOverlayPage(Widget page) => overlayStack.add(page);
  void popOverlayPage() {
    if (overlayStack.isNotEmpty) overlayStack.removeLast();
  }

  Widget? get currentOverlay =>
      overlayStack.isNotEmpty ? overlayStack.last : null;

  void clearOverlays() => overlayStack.clear();
}

// ------------ CUSTOM BOTTOM NAVIGATION BAR ------------
class CustomBottomNavigationBar extends StatefulWidget {
  @override
  State<CustomBottomNavigationBar> createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  final BottomNavController controller = Get.find<BottomNavController>();

  final contactsController = Get.find<ContactsController>();

  final List<_NavItemData> _items = [
    _NavItemData(imagePath: 'assets/images/Explore.png', label: 'Explore'),
    _NavItemData(imagePath: 'assets/images/Ranking.png', label: 'Ranking'),
    _NavItemData(imagePath: 'assets/images/Add.png', label: 'Add'),
    _NavItemData(imagePath: 'assets/images/Chat.png', label: 'Chat'),
    _NavItemData(imagePath: 'assets/images/User.png', label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final itemWidth = MediaQuery.of(context).size.width / _items.length;

    return SafeArea(
      top: false,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Container(
              height: 80.h,
              color: appColors.purple,
              child: Obx(() {
                final selectedIndex = controller.selectedIndex.value;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_items.length, (index) {
                    final item = _items[index];
                    final isSelected = selectedIndex == index;

                    return GestureDetector(
                      onTap: () => controller.changeIndex(index),
                      behavior: HitTestBehavior.translucent,
                      child: SizedBox(
                        width: itemWidth,
                        height: 95.h,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            if (!isSelected)
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Image.asset(
                                          item.imagePath,
                                          width: 28.w,
                                          height: 28.h,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                        if (index == 3) // 👈 Chat icon index
                                          Positioned(
                                            top: -2,
                                            right: -2,
                                            child: Obx(() {
                                              final count =
                                                  contactsController
                                                      .totalUnread
                                                      .value;
                                              if (count == 0)
                                                return const SizedBox.shrink();
                                              return Container(
                                                padding: EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints: BoxConstraints(
                                                  minWidth: 20.w,
                                                  minHeight: 20.h,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    count > 99
                                                        ? '99+'
                                                        : count.toString(),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10.sp,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // const SizedBox(height: 4),
                                  // Text(
                                  //   item.label,
                                  //   style: TextStyle(
                                  //     color: Colors.white.withOpacity(0.6),
                                  //     fontSize: 10.sp,
                                  //     fontWeight: FontWeight.w600,
                                  //   ),
                                  // ),
                                ],
                              ),
                            if (isSelected)
                              Positioned(
                                bottom: 20.h,
                                child: Text(
                                  item.label,
                                  style: appThemes.small.copyWith(
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
          // Floating selected icon
          Obx(() {
            final selectedIndex = controller.selectedIndex.value;
            final item = _items[selectedIndex];
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: selectedIndex * itemWidth + (itemWidth - 60.w) / 2,
              top: -30.h,
              child: Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  color: appColors.purple,
                  shape: BoxShape.circle,
                  border: Border.all(width: 2, color: appColors.white),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    item.imagePath,
                    fit: BoxFit.contain,
                    color: appColors.white,
                    width: 30.w,
                    height: 30.h,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ------------ MAIN SCREEN VIEW (USES PAGEVIEW) ------------
class MainScreenView extends StatefulWidget {
  MainScreenView({super.key});

  @override
  State<MainScreenView> createState() => _MainScreenViewState();
}

class _MainScreenViewState extends State<MainScreenView> {
  final ContactsController contactsController = Get.put(ContactsController());
  // ✅ Register it here
  final BottomNavController navController = Get.put(BottomNavController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final overlay = navController.currentOverlay;
      return Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: Stack(
          children: [
            PageView(
              controller: navController.pageController,
              onPageChanged:
                  (index) => navController.selectedIndex.value = index,
              children: [
                Explore(),
                LeaderboardView(),
                AddView(),
                ContactsView(),
                ProfileView(),
              ],
            ),
            if (overlay != null) overlay,
          ],
        ),
        bottomNavigationBar: CustomBottomNavigationBar(),
      );
    });
  }
}
