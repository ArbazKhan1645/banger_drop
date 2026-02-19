import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/add_banger/widgets/colored_textfield_widget.dart';
import 'package:banger_drop/views/add_banger/widgets/dropdown_widget.dart';
import 'package:banger_drop/views/add_playlist.dart/controller/playlist_controler.dart';
import 'package:banger_drop/views/add_playlist.dart/wdigets/recent_banger_widge.dart';
import 'package:banger_drop/views/widgets/bottom_navigation_bar/bottonBar.dart';
import 'package:banger_drop/views/widgets/buttons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddPlayListView extends StatefulWidget {
  const AddPlayListView({super.key});

  @override
  State<AddPlayListView> createState() => _AddPlayListViewState();
}

class _AddPlayListViewState extends State<AddPlayListView> {
  final controller = Get.put(PlaylistController());
  final BottomNavController BottomBarcontroller =
      Get.find<BottomNavController>();

  @override
  void initState() {
    super.initState();
    AppConstants.initializeUserData();
    controller.fetchLikedBangersForCurrentUser(AppConstants.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/Picture1.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Obx(() {
                final bangers = controller.likedBangers;
                final selectedBangers = controller.selectedBangers;
                final selectedYoutubeBangers =
                    controller.selectedYoutubeBangers;

                return ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    const SizedBox(height: 50),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Icon(
                            Icons.arrow_back_ios_rounded,
                            color: appColors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 35),
                    Text(
                      'Playlist title',
                      style: appThemes.Medium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CustomTextField(
                      controller: controller.title,
                      suggestions: [],
                      maxLines: 1,
                      hint: "",
                    ),
                    const SizedBox(height: 10),

                    /// Genre and Subgenre
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

                    const SizedBox(height: 10),
                    Text(
                      'Add a picture',
                      style: appThemes.Medium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Obx(() {
                      final image = controller.pickedImage.value;
                      return SizedBox(
                        width: 200,
                        child:
                            image != null
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
                                ),
                      );
                    }),

                    const SizedBox(height: 10),
                    Text(
                      'Description',
                      style: appThemes.Medium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CustomTextField(
                      controller: controller.description,
                      suggestions: [],
                      maxLines: 5,
                      hint: "",
                    ),

                    const SizedBox(height: 10),
                    Text(
                      'Tags',
                      style: appThemes.Medium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CustomTextField(
                      controller: controller.tags,
                      suggestions: [],
                      maxLines: 1,
                      hint: "",
                    ),

                    const SizedBox(height: 30),

                    /// 🔷 Add Banger Section
                    Text(
                      "Add Banger",
                      style: appThemes.Medium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...selectedYoutubeBangers.map(
                      (banger) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: RecentBangerWidget(
                          artist: banger['artist'],
                          title: banger['title'],
                          imageUrl: banger['imageUrl'],
                          isSelected: true,
                          onPlay: () {},
                          onDownload: () {},
                        ),
                      ),
                    ),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final song =
                              await controller.showYoutubeSearchDialog();
                          if (song != null) {
                            controller.addYoutubeBanger({
                              'title': song['title'],
                              'artist': song['channel'],
                              'imageUrl': song['thumbnail'],
                              'audioUrl': song['audioUrl'],
                              'youtubeSong': true,
                              'id':
                                  DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                            });
                          }
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.purpleAccent,
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// 🔷 Add Recent Banger Section
                    /// 🔷 Add Recent Banger Section
                    Obx(() {
                      final likedBangers = controller.likedBangers;

                      if (likedBangers.isEmpty) {
                        return SizedBox();
                      }

                      return SizedBox(
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: likedBangers.length,
                          itemBuilder: (context, index) {
                            final doc = likedBangers[index];
                            final bangerData =
                                doc.data() as Map<String, dynamic>;
                            final banger = {...bangerData, 'id': doc.id};

                            final isSelected = controller.selectedBangers.any(
                              (item) => item['id'] == banger['id'],
                            );

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  controller.toggleBangerSelection(doc);
                                });
                              },
                              child: RecentBangerWidget(
                                artist: banger['artist'] ?? '',
                                title: banger['title'] ?? '',
                                imageUrl: banger['imageUrl'] ?? '',
                                isSelected: isSelected,
                                onPlay: () {},
                                onDownload: () {},
                              ),
                            );
                          },
                        ),
                      );
                    }),

                    const SizedBox(height: 20),
                    Center(
                      child: GradientDropButton(
                        onTap: () async {
                          FocusScope.of(context).unfocus();
                          bool success = await controller.submitPlaylist();
                          if (success) {
                            BottomBarcontroller.selectedIndex.value = 0;
                            Get.offAll(() => MainScreenView());
                          }
                        },
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
