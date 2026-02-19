// AddUnknownBanger.dart
import 'dart:async';
import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/Explore/widgets/search_textfield.dart';
import 'package:banger_drop/views/add_banger/controller/unknown_banger_controller.dart';
import 'package:banger_drop/views/add_banger/widgets/colored_textfield_widget.dart';
import 'package:banger_drop/views/add_banger/widgets/dropdown_widget.dart';
import 'package:banger_drop/views/widgets/bottom_navigation_bar/bottonBar.dart';
import 'package:banger_drop/views/widgets/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class AddUnknownBanger extends StatefulWidget {
  const AddUnknownBanger({super.key});

  @override
  State<AddUnknownBanger> createState() => _AddUnknownBangerState();
}

class _AddUnknownBangerState extends State<AddUnknownBanger> {
  final controller = Get.put(BangerController());
  final BottomNavController BottomBarcontroller =
      Get.find<BottomNavController>();
  @override
  void initState() {
    controller.fetchUserPlaylists();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/Picture1.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 50),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: appColors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      buildLabel('Title'),
                      CustomTextField(
                        controller: controller.title.value,
                        suggestions: [],
                        maxLines: 1,
                        hint: "",
                      ),
                      SizedBox(height: 10),
                      buildLabel('Artist'),
                      CustomTextField(
                        controller: controller.Artist.value,
                        suggestions: [],
                        maxLines: 1,
                        hint: "",
                      ),
                      SizedBox(height: 10),
                      buildLabel('Add Youtube link'),
                      Obx(
                        () => CustomTextField(
                          controller: controller.link.value,
                          suggestions: [],
                          maxLines: 1,
                          hint: "",
                          suffixIcon:
                              controller.link.value.text.isNotEmpty
                                  ? IconButton(
                                    icon: Icon(Icons.clear),
                                    onPressed:
                                        () => controller.link.value.clear(),
                                  )
                                  : null,
                        ),
                      ),
                      SizedBox(height: 10),
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
                                    selectedItem:
                                        controller.selectedGenre.value,
                                    hintText: "Select Genre",
                                    onChanged:
                                        (value) =>
                                            controller.selectGenre(value!),
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
                      buildLabel('Description'),
                      CustomTextField(
                        controller: controller.Description.value,
                        suggestions: [],
                        maxLines: 5,
                        hint: "",
                      ),
                      SizedBox(height: 10),
                      buildLabel('Add a picture'),
                      SizedBox(
                        width: 200,
                        child: Obx(() {
                          final image = controller.pickedImage.value;
                          return image != null
                              ? GestureDetector(
                                onTap: controller.pickImage,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: Image.file(image, fit: BoxFit.cover),
                                ),
                              )
                              : RectengleButton(
                                text: 'Add picture',
                                borderColor: appColors.white,
                                textColor: appColors.white,
                                onPressed: controller.pickImage,
                              );
                        }),
                      ),
                      SizedBox(height: 10),
                      buildLabel('Tags'),
                      CustomTextField(
                        controller: controller.Tags.value,
                        suggestions: [],
                        maxLines: 1,
                        hint: "",
                      ),
                      // SizedBox(height: 10),
                      // Obx(() {
                      //   if (controller.isLinkEntered.value)
                      //     return SizedBox(); // ✅ hide music section

                      //   final path = controller.audioPath.value;
                      //   return Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       buildLabel('Add music file'),
                      //       const SizedBox(height: 10),
                      //       SizedBox(
                      //         width: 200,
                      //         child:
                      //             path.isEmpty
                      //                 ? RectengleButton(
                      //                   text: '.mp3',
                      //                   borderColor: appColors.white,
                      //                   textColor: appColors.white,
                      //                   onPressed: controller.pickAudio,
                      //                 )
                      //                 : Column(
                      //                   children: [
                      //                     Icon(
                      //                       Icons.music_note,
                      //                       color: appColors.white,
                      //                       size: 30,
                      //                     ),
                      //                     const SizedBox(height: 8),
                      //                     Text(
                      //                       path.split('/').last,
                      //                       style: TextStyle(
                      //                         color: appColors.white,
                      //                       ),
                      //                       overflow: TextOverflow.ellipsis,
                      //                     ),
                      //                   ],
                      //                 ),
                      //       ),
                      //     ],
                      //   );
                      // }),
                      SizedBox(height: 10),
                      buildLabel('Add to a playlist'),
                      SizedBox(height: 10),
                      Obx(() {
                        if (controller.playlistItems.isEmpty) {
                          return const CircularProgressIndicator();
                        }
                        return CustomDropdown(
                          items: controller.playlistItems,
                          selectedItem: controller.selectedPlaylist.value,
                          onChanged: (value) {
                            if (value != null) {
                              controller.selectedPlaylist.value = value;
                              final index = controller.playlistItems.indexOf(
                                value,
                              );
                              if (index != -1 &&
                                  index < controller.playlistIds.length) {
                                controller.selectedPlaylistId.value =
                                    controller.playlistIds[index];
                                controller.selectedPlaylistImage.value =
                                    controller.playlistImges[index];
                              }
                            }
                          },
                        );
                      }),
                      SizedBox(height: 20),
                      Center(
                        child: GradientDropButton(
                          onTap: () async {
                            FocusScope.of(
                              context,
                            ).unfocus(); // Dismiss keyboard

                            bool success =
                                await controller.submitBanger(); // Submit data

                            if (success) {
                              BottomBarcontroller.selectedIndex.value = 0;
                              Get.offAll(() => MainScreenView());
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLabel(String text) {
    return Text(
      text,
      style: appThemes.Medium.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
