import 'dart:io';
import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/add_banger/controller/add_banger_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class PlaylistController extends GetxController {
  Rx<File?> pickedImage = Rx<File?>(null);

  final title = TextEditingController();
  final description = TextEditingController();
  final tags = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

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
  };

  RxString selectedGenre = ''.obs;
  RxString selectedSubGenre = ''.obs;

  List<String> get subGenres => genreMap[selectedGenre.value] ?? [];

  void selectGenre(String genre) {
    selectedGenre.value = genre;
    selectedSubGenre.value = '';
  }

  void selectSubGenre(String sub) {
    selectedSubGenre.value = sub;
    print('Selected SubGenre: $sub');
  }

  Future<void> pickImage() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) pickedImage.value = File(image.path);
  }

  Future<String?> uploadImageToFirebase(File file) async {
    final fileName = const Uuid().v4();
    final ref = FirebaseStorage.instance.ref().child("images/$fileName.jpg");
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  var likedBangers = <QueryDocumentSnapshot>[].obs;
  Future<void> fetchLikedBangersForCurrentUser(String userId) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('Bangers').get();

      final List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered = [];

      for (var doc in querySnapshot.docs) {
        final List likes = doc.data()['Likes'] ?? [];

        final hasLiked = likes.any((like) => like['id'] == userId);
        if (hasLiked) {
          filtered.add(doc);
        }
      }

      likedBangers.value = filtered;
    } catch (e) {
      print("Error fetching liked bangers: $e");
    }
  }

  Future<bool> submitPlaylist() async {
    // Validation
    if (title.text.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields');
      return false;
    }
    // if (selectedGenre.isEmpty || selectedSubGenre.isEmpty) {
    //   Get.snackbar('Error', 'Please select genre and sub-genre');
    //   return false;
    // }
    if (pickedImage.value == null) {
      Get.snackbar('Error', 'Please pick an image');
      return false;
    }

    // Show loading dialog
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      String id = DateTime.now().millisecondsSinceEpoch.toString();
      String imageUrl = await uploadImageToFirebase(pickedImage.value!) ?? '';
      // Upload YouTube bangers first
      for (var banger in selectedYoutubeBangers) {
        final String bangerId =
            DateTime.now().millisecondsSinceEpoch.toString();
        banger['id'] = bangerId;
        selectedBangers.add(banger);

        await FirebaseFirestore.instance
            .collection("Bangers")
            .doc(bangerId)
            .set({
              'title': banger['title'],
              'search_title': banger['title'].toString().toLowerCase(),
              'artist': banger['artist'] ?? banger['channel'],
              'link': '',
              'description': description.text,
              'tags': tags.text.split(' '),
              'playlistName': title.text,
              'playlistId': id,
              'playlistImg': '', // You can set this to imageUrl later if needed
              'imageUrl': banger['imageUrl'],
              'audioUrl': banger['audioUrl'],
              'TotalLikes': 0,
              'Totalcomments': 0,
              'TotalShares': 0,
              'plays': 0,
              'comments': [],
              'Likes': [],
              'shares': [],
              'createdAt': FieldValue.serverTimestamp(),
              'CreatedBy': user?.uid,
              'id': bangerId,
              'UserImage': AppConstants.userImg,
              'genre': selectedGenre.value,
              'subGenre': selectedSubGenre.value,
              'youtubeSong': true,
              'isRawLink': false,
              'isbanger': false,
            });
      }

      await FirebaseFirestore.instance.collection('Playlist').doc(id).set({
        'id': id,
        'title': title.text,
        'search_title': title.text.toLowerCase(),
        'description': description.text,
        'tags': tags.text.split(' '),
        'genre': selectedGenre.value,
        'subGenre': selectedSubGenre.value,
        'image': imageUrl,
        'bangers': selectedBangers,
        'createdAt': FieldValue.serverTimestamp(),
        'created By': user?.uid,
        'authorName': AppConstants.userName,
        'isbanger': false,
      });

      await awardPointsIfEligible();

      // Reset form
      title.clear();
      description.clear();
      tags.clear();
      pickedImage.value = null;
      selectedGenre.value = '';
      selectedSubGenre.value = '';
      selectedBangers.clear();

      Get.back(); // Close dialog
      Get.snackbar('Success', 'Playlist created successfully');
      return true;
    } catch (e) {
      Get.back(); // Close dialog
      Get.snackbar('Error', 'Something went wrong: $e');
      return false;
    }
  }

  Future<void> awardPointsIfEligible() async {
    final uid = user?.uid;
    if (uid == null) return;

    final playlistSnapshot =
        await FirebaseFirestore.instance
            .collection('Playlist')
            .where('created By', isEqualTo: uid)
            .get();

    final totalPlaylists = playlistSnapshot.docs.length;
    final now = Timestamp.now();

    int points = 0;
    final List<Map<String, dynamic>> historyToAdd = [];

    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    final userSnap = await userDoc.get();
    final lastMilestone = userSnap.data()?['lastPlaylistMilestone'] ?? 0;

    // ✅ First playlist and 10+ bangers
    if (totalPlaylists == 1 && selectedBangers.length >= 10) {
      points += 10;
      historyToAdd.add({
        'points': 10,
        'timestamp': now,
        'reason': 'First playlist with 10+ bangers',
        'playlistId': playlistSnapshot.docs.first.id,
      });
    }

    // ✅ Exactly 5 playlists
    if (totalPlaylists == 5) {
      points += 100;
      historyToAdd.add({
        'points': 100,
        'timestamp': now,
        'reason': '5 playlists created',
        'playlistId': playlistSnapshot.docs.last.id,
      });
    }

    // ✅ Every 5 playlists (excluding the above 5th one if already rewarded)
    if (totalPlaylists > 5 &&
        totalPlaylists % 5 == 0 &&
        totalPlaylists > lastMilestone) {
      points += 100;
      historyToAdd.add({
        'points': 100,
        'timestamp': now,
        'reason': '$totalPlaylists playlists created',
        'playlistId': playlistSnapshot.docs.last.id,
      });
    }

    if (points > 0) {
      await userDoc.update({
        'points': FieldValue.increment(points),
        'pointsHistory': FieldValue.arrayUnion(historyToAdd),
        'lastPlaylistMilestone': totalPlaylists,
      });

      AppConstants.points =
          ((int.tryParse(AppConstants.points.toString()) ?? 0) + points)
              .toString();
    }

    await AppConstants.initializeUserData();
  }

  RxList<DocumentSnapshot> bangers = <DocumentSnapshot>[].obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fetchBangersByUser(String id) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('Bangers')
              .where('CreatedBy', isEqualTo: id)
              .orderBy('createdAt', descending: true)
              .get();

      bangers.value = snapshot.docs;
      print("Fetched \${bangers.length} bangers.");
    } catch (e) {
      print("Error fetching bangers: $e");
    }
  }

  RxList<Map<String, dynamic>> selectedBangers = <Map<String, dynamic>>[].obs;

  void toggleBangerSelection(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final banger = {...data, 'id': doc.id};

    final index = selectedBangers.indexWhere(
      (item) => item['id'] == banger['id'],
    );
    if (index != -1) {
      selectedBangers.removeAt(index);
    } else {
      selectedBangers.add(banger);
    }
  }

  void addYoutubeBanger(Map<String, dynamic> bangerData) {
    bangerData['id'] ??= DateTime.now().microsecondsSinceEpoch.toString();

    final alreadyExists = selectedYoutubeBangers.any(
      (item) => item['id'] == bangerData['id'],
    );
    if (!alreadyExists) {
      selectedYoutubeBangers.add(bangerData);
    }
  }

  var selectedYoutubeBangers = <Map<String, dynamic>>[].obs;

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
