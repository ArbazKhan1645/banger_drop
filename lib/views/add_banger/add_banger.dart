import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/add_banger/add_unknown_banger.dart';
import 'package:banger_drop/views/add_banger/controller/add_banger_controller.dart';
import 'package:banger_drop/views/add_banger/widgets/colored_textfield_widget.dart';
import 'package:banger_drop/views/add_banger/widgets/dropdown_widget.dart';
import 'package:banger_drop/views/widgets/bottom_navigation_bar/bottonBar.dart';
import 'package:banger_drop/views/widgets/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class AddBanger extends StatelessWidget {
  AddBanger({super.key});
  final controller = Get.put(AddBangerController());
  final BottomNavController BottomBarcontroller =
      Get.find<BottomNavController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Picture1.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BackButton(color: Colors.white),
                    const Text(
                      "Drop your banger",
                      style: TextStyle(color: Colors.white, fontSize: 22),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final result =
                            await controller.showYoutubeSearchDialog();
                        if (result != null) {
                          controller.selectedYoutubeSong.value = result;
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        width: ScreenUtil().screenWidth,
                        height: 50,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: appColors.textGrey),
                              SizedBox(width: 12.w),
                              Text(
                                'Search bangers ...',
                                style: appThemes.small.copyWith(
                                  fontFamily: 'Sans',
                                  color: appColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Obx(
                    //   () => GestureDetector(
                    //     onTap: () => openBangerSelectionDialog(context),
                    //     child: Container(
                    //       padding: const EdgeInsets.symmetric(
                    //         horizontal: 16,
                    //         vertical: 16,
                    //       ),
                    //       decoration: BoxDecoration(
                    //         color: Colors.grey[850],
                    //         borderRadius: BorderRadius.circular(12),
                    //         border: Border.all(color: Colors.white24),
                    //       ),
                    //       child: Row(
                    //         children: [
                    //           const Icon(Icons.music_note, color: Colors.white),
                    //           const SizedBox(width: 12),
                    //           Expanded(
                    //             child: Text(
                    //               controller.selectedBangerTitle.value.isEmpty
                    //                   ? 'Select a banger'
                    //                   : controller.selectedBangerTitle.value,
                    //               style: TextStyle(
                    //                 color:
                    //                     controller
                    //                             .selectedBangerTitle
                    //                             .value
                    //                             .isEmpty
                    //                         ? Colors.white54
                    //                         : Colors.white,
                    //               ),
                    //             ),
                    //           ),
                    //           const Icon(
                    //             Icons.arrow_drop_down,
                    //             color: Colors.white,
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Get.to(() => const AddUnknownBanger()),
                        child: Text(
                          "Banger Not Found?",
                          style: appThemes.small.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Description",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    CustomTextField(
                      controller: controller.descriptionController,
                      suggestions: [],
                      maxLines: 3,
                      hint: '',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Tags",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    CustomTextField(
                      controller: controller.tagsController,
                      suggestions: [],
                      maxLines: 1,
                      hint: '',
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Genre',
                                style: appThemes.Medium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Obx(
                                () => StyledDropdown(
                                  items: controller.genreMap.keys.toList(),
                                  selectedItem: controller.selectedGenre.value,
                                  hintText: "Select Genre",
                                  onChanged:
                                      (value) => controller.selectGenre(value!),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sub-genre',
                                style: appThemes.Medium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Obx(
                                () => StyledDropdown(
                                  items: controller.subGenres,
                                  selectedItem:
                                      controller.selectedSubGenre.value,
                                  hintText: "Select Sub-Genre",
                                  onChanged:
                                      (value) =>
                                          controller.selectSubGenre(value!),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      "Add to a playlist",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Obx(
                      () => CustomDropdown(
                        items: controller.playlistItems,
                        selectedItem: controller.selectedPlaylist.value,
                        onChanged:
                            (value) => controller.selectPlaylistByName(value!),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     Obx(
                    //       () =>
                    //           controller.isUploading.value
                    //               ? const Center(
                    //                 child: CircularProgressIndicator(
                    //                   color: Colors.white,
                    //                 ),
                    //               )
                    //               : GradientDropButton(
                    //                 onTap: () async {
                    //                   FocusScope.of(context).unfocus();
                    //                   bool success =
                    //                       await controller.addBanger();
                    //                   if (success) {
                    //                     BottomBarcontroller
                    //                         .selectedIndex
                    //                         .value = 0;
                    //                     Get.offAll(() => MainScreenView());
                    //                   }
                    //                 },
                    //               ),
                    //     ),

                    //   ],
                    // ),
                    const SizedBox(height: 20),

                    // Drop button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Obx(
                          () =>
                              controller.isUploading.value
                                  ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                  : GradientDropButton(
                                    onTap: () async {
                                      FocusScope.of(context).unfocus();
                                      bool success =
                                          await controller.addBanger();
                                      if (success) {
                                        BottomBarcontroller
                                            .selectedIndex
                                            .value = 0;
                                        Get.offAll(() => MainScreenView());
                                      }
                                    },
                                  ),
                        ),
                      ],
                    ),

                    // Show selected song from YouTube (if any)
                    Obx(() {
                      final song = controller.selectedYoutubeSong.value;
                      if (song == null) return const SizedBox.shrink();

                      return Container(
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                song['thumbnail'] ?? '',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => const Icon(
                                      Icons.error,
                                      color: Colors.red,
                                    ),
                                loadingBuilder:
                                    (context, child, loadingProgress) =>
                                        loadingProgress == null
                                            ? child
                                            : const CircularProgressIndicator(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song['title'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    song['channel'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                controller.selectedYoutubeSong.value = null;
                              },
                              child: Icon(Icons.close, color: appColors.white),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
