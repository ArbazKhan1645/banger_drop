import 'dart:async';

import 'package:banger_drop/consts/consts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AddBangerController extends GetxController {
  final Map<String, List<String>> genreMap = {
    'Hip Hop': ['Trap', 'Boom Bap', 'Drill', 'Lo-fi'],
    'Electronic': ['House', 'Trance', 'Dubstep', 'Techno'],
    'Rock': ['Alternative', 'Hard Rock', 'Indie Rock', 'Classic Rock'],
    'Pop': ['Dance Pop', 'Electropop', 'Synthpop'],
    'Jazz': ['Smooth Jazz', 'Bebop', 'Swing'],
    'Classical': ['Baroque', 'Romantic', 'Contemporary'],
    'Reggae': ['Roots', 'Dub', 'Dancehall'],
    'R&B': ['Neo Soul', 'Funk', 'Contemporary R&B'],
    'Country': ['Bluegrass', 'Honky Tonk', 'Modern Country'],
    'Other': ['Other'],
  };

  RxString selectedGenre = ''.obs;
  RxString selectedSubGenre = ''.obs;
  List<String> get subGenres => genreMap[selectedGenre.value] ?? [];

  void selectSubGenre(String sub) {
    selectedSubGenre.value = sub;
    print('Selected SubGenre: $sub');
  }

  void selectGenre(String genre) {
    selectedGenre.value = genre;
    selectedSubGenre.value = '';
  }

  RxString selectedBangerTitle = ''.obs;
  Rxn<Map<String, dynamic>> selectedBanger = Rxn<Map<String, dynamic>>();
  RxList<Map<String, dynamic>> allBangers = <Map<String, dynamic>>[].obs;

  RxList<String> playlistItems = ['Select'].obs;
  RxList<String> playlistIds = [''].obs;
  RxString selectedPlaylist = 'Select'.obs;
  RxString selectedPlaylistId = ''.obs;
  Rxn<Map<String, dynamic>> selectedYoutubeSong = Rxn<Map<String, dynamic>>();
  RxList<String> playlistImages = [''].obs;

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();

  RxBool isUploading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserPlaylists();
    fetchAllBangers();
  }

  void fetchUserPlaylists() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('Playlist')
            .where('created By', isEqualTo: uid)
            .get();

    final titles = ['Select'];
    final ids = [''];
    final images = ['']; // corresponding index for images

    for (var doc in snapshot.docs) {
      titles.add(doc['title']);
      ids.add(doc.id);
      images.add(doc['image'] ?? '');
    }

    playlistItems.value = titles;
    playlistIds.value = ids;
    playlistImages.value = images;

    selectedPlaylist.value = titles.first;
  }

  void fetchAllBangers() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('Bangers').get();

    final bangers =
        snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

    allBangers.value = bangers;
  }

  void setSelectedBanger(Map<String, dynamic> banger) {
    selectedBanger.value = banger;
    selectedBangerTitle.value = banger['title'] ?? '';
  }

  String getSelectedPlaylistImage() {
    final index = playlistItems.indexOf(selectedPlaylist.value);
    if (index != -1 && index < playlistImages.length) {
      return playlistImages[index];
    }
    return ''; // fallback
  }

  void selectPlaylistByName(String name) {
    final index = playlistItems.indexOf(name);
    selectedPlaylist.value = name;
    selectedPlaylistId.value = index != -1 ? playlistIds[index] : '';
  }

  Future<void> addToPlaylistListField({
    required String docId,
    required String fieldName,
    required dynamic valueToAdd,
  }) async {
    final docRef = FirebaseFirestore.instance.collection('Playlist').doc(docId);
    await docRef.update({
      fieldName: FieldValue.arrayUnion([valueToAdd]),
    });
  }

  Future<bool> addBanger() async {
    if (selectedYoutubeSong.value == null) {
      Get.snackbar('Error', 'Please select a banger first');
      return false;
    }

    isUploading.value = true;
    final String id = DateTime.now().microsecondsSinceEpoch.toString();
    final uid = AppConstants.userId;
    final now = Timestamp.now();

    try {
      // ✅ 1. Create Banger
      await FirebaseFirestore.instance.collection("Bangers").doc(id).set({
        'title': selectedYoutubeSong.value?['title'],
        'search_title':
            selectedYoutubeSong.value?['title'].toString().toLowerCase(),
        'artist': selectedYoutubeSong.value?['channel'],
        'link': '',
        'description': descriptionController.text,
        'tags': tagsController.text.split(' '),
        'playlistName': selectedPlaylist.value,
        'playlistId': selectedPlaylistId.value,
        'playlistImg': getSelectedPlaylistImage(),
        'imageUrl': selectedYoutubeSong.value?['thumbnail'],
        'audioUrl': selectedYoutubeSong.value?['audioUrl'],
        'TotalLikes': 0,
        'Totalcomments': 0,
        'TotalShares': 0,
        'plays': 0,
        'comments': [],
        'Likes': [],
        'shares': [],
        'createdAt': now,
        'CreatedBy': uid,
        'id': id,
        'UserImage': AppConstants.userImg,
        'genre': selectedGenre.value,
        'subGenre': selectedSubGenre.value,
        'youtubeSong': true,
        'isRawLink': false,
        'isbanger': true,
      });

      // ✅ 2. Add to Playlist
      if (selectedPlaylistId.value != '') {
        await addToPlaylistListField(
          docId: selectedPlaylistId.value,
          fieldName: 'bangers',
          valueToAdd: {
            'title': selectedYoutubeSong.value?['title'],
            'artist': selectedYoutubeSong.value?['channel'],
            'imageUrl': selectedYoutubeSong.value?['thumbnail'],
            'audioUrl': selectedYoutubeSong.value?['audioUrl'],
            'id': id,
            'youtubeSong': true,
            'isRawLink': false,
          },
        );
      }

      // ✅ 3. Milestone Logic with Points & Timestamp
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
      final userSnap = await userDoc.get();

      final totalBangers =
          (await FirebaseFirestore.instance
                  .collection('Bangers')
                  .where('CreatedBy', isEqualTo: uid)
                  .get())
              .docs
              .length;

      int pointsToAdd = 0;
      final lastMilestone = userSnap.data()?['lastBangerMilestone'] ?? 0;
      final List<Map<String, dynamic>> historyToAdd = [];

      if (totalBangers == 1) {
        pointsToAdd += 5;
        historyToAdd.add({
          'points': 5,
          'timestamp': now,
          'reason': 'First banger upload',
          'bangerId': id,
        });
      }
      if (totalBangers == 10) {
        pointsToAdd += 25;
        historyToAdd.add({
          'points': 25,
          'timestamp': now,
          'reason': '10 bangers uploaded',
          'bangerId': id,
        });
      }
      if (totalBangers == 50) {
        pointsToAdd += 100;
        historyToAdd.add({
          'points': 100,
          'timestamp': now,
          'reason': '50 bangers uploaded',
          'bangerId': id,
        });
      }
      if (totalBangers == 100) {
        pointsToAdd += 100;
        historyToAdd.add({
          'points': 100,
          'timestamp': now,
          'reason': '100 bangers uploaded',
          'bangerId': id,
        });
      }
      if (totalBangers == 500) {
        pointsToAdd += 200;
        historyToAdd.add({
          'points': 200,
          'timestamp': now,
          'reason': '500 bangers uploaded',
          'bangerId': id,
        });
      }
      if (totalBangers == 1000) {
        pointsToAdd += 500;
        historyToAdd.add({
          'points': 500,
          'timestamp': now,
          'reason': '1000 bangers uploaded',
          'bangerId': id,
        });
      }

      if (totalBangers > 1000) {
        int from = (lastMilestone <= 1000) ? 1100 : lastMilestone + 100;
        for (int i = from; i <= totalBangers; i += 100) {
          int milestonePoints = (i % 1000 == 0) ? 100 : 50;
          pointsToAdd += milestonePoints;
          historyToAdd.add({
            'points': milestonePoints,
            'timestamp': now,
            'reason': '$i bangers uploaded',
            'bangerId': id,
          });
        }
      }

      if (pointsToAdd > 0) {
        await userDoc.update({
          'points': FieldValue.increment(pointsToAdd),
          'lastBangerMilestone': totalBangers,
          'pointsHistory': FieldValue.arrayUnion(historyToAdd),
        });

        AppConstants.points =
            ((int.tryParse(AppConstants.points.toString()) ?? 0) + pointsToAdd)
                .toString();
      }

      // ✅ 4. Finalize
      resetForm();
      Get.snackbar('Success', 'Banger added successfully!');
      return true;
    } catch (e) {
      isUploading.value = false;
      Get.snackbar('Error', 'Failed to add banger: $e');
      return false;
    }
  }

  void resetForm() {
    isUploading.value = false;
    selectedBanger.value = null;
    selectedBangerTitle.value = '';
    descriptionController.clear();
    tagsController.clear();
    selectedPlaylist.value = 'Select';
    selectedPlaylistId.value = '';
  }

  Future<Map<String, dynamic>?> showYoutubeSearchDialog() async {
    final YoutubeSearchController controller = Get.put(
      YoutubeSearchController(),
    );
    final TextEditingController searchController = TextEditingController();

    return await Get.dialog<Map<String, dynamic>>(
      Dialog(
        backgroundColor: Colors.grey[900],
        insetPadding: const EdgeInsets.all(10),
        child: Container(
          padding: const EdgeInsets.all(16),
          height: Get.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Search Songs ",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter song name...',
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.black54,
                  prefixIcon: Icon(Icons.search, color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged:
                    controller.onSearchChanged, // 🔄 this is the new debounce
              ),

              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.searchResults.isEmpty) {
                    return Center(
                      child: Text(
                        "No results",
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: controller.searchResults.length,
                    itemBuilder: (context, index) {
                      final item = controller.searchResults[index];
                      final snippet = item['snippet'];
                      final title = snippet['title'];
                      final channelTitle = snippet['channelTitle'];
                      final thumbnail = snippet['thumbnails']['default']['url'];

                      return ListTile(
                        leading: CachedNetworkImage(
                          imageUrl: thumbnail,
                          placeholder:
                              (context, url) => const SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) =>
                                  const Icon(Icons.error, color: Colors.red),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                        title: Text(maxLines: 3, title, style: appThemes.small),
                        subtitle: Text(
                          channelTitle,
                          style: appThemes.small.copyWith(
                            fontFamily: 'Sans',
                            color: appColors.white.withOpacity(.5),
                          ),
                        ),
                        onTap: () {
                          Get.back(
                            result: {
                              'title': title,
                              'channel': channelTitle,
                              'thumbnail': thumbnail,
                              'videoId': item['id']['videoId'],
                              'audioUrl':
                                  'https://www.youtube.com/watch?v=${item['id']['videoId']}',
                            },
                          );
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class YoutubeSearchController extends GetxController {
  final apiKey = "AIzaSyCKnFqyI1l9BuOPtH_RX-FyxlMKAXAmaGI";
  var searchResults = [].obs;
  var isLoading = false.obs;

  Timer? _debounce;

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchSongs(query);
    });
  }

  Future<void> searchSongs(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }

    isLoading.value = true;
    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=10&q=$query&key=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        searchResults.value = data['items'];
      } else {
        print("Error: ${response.body}");
        searchResults.clear();
      }
    } catch (e) {
      print("Exception: $e");
      searchResults.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
