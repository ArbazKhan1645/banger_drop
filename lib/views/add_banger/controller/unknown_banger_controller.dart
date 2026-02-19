import 'dart:io';
import 'package:banger_drop/consts/consts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class BangerController extends GetxController {
  RxString selectedGenre = ''.obs;
  RxString selectedSubGenre = ''.obs;
  List<String> get subGenres => genreMap[selectedGenre.value] ?? [];
  Rx<TextEditingController> title = TextEditingController().obs;
  Rx<TextEditingController> Artist = TextEditingController().obs;
  Rx<TextEditingController> link = TextEditingController().obs;
  Rx<TextEditingController> Description = TextEditingController().obs;
  Rx<TextEditingController> Tags = TextEditingController().obs;
  final RxList<Map<String, dynamic>> selectedBangers =
      <Map<String, dynamic>>[].obs;
  final RxBool showSearchBar = false.obs;
  final Rx<TextEditingController> bangerSearchController =
      TextEditingController().obs;
  final RxList<Map<String, dynamic>> searchResults =
      <Map<String, dynamic>>[].obs;

  Rx<File?> pickedImage = Rx<File?>(null);
  RxString audioPath = ''.obs;

  RxString selectedPlaylist = 'Playlist 1'.obs;
  RxList<String> playlistItems = <String>[].obs;
  RxList<String> playlistIds = <String>[].obs;
  RxList<String> playlistImges = <String>[].obs;
  RxString selectedPlaylistId = ''.obs;
  RxString selectedPlaylistImage = ''.obs;
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
  RxBool isLinkEntered = false.obs;
  void selectGenre(String genre) {
    selectedGenre.value = genre;
    selectedSubGenre.value = '';
  }

  void selectSubGenre(String sub) {
    selectedSubGenre.value = sub;
    print('Selected SubGenre: $sub');
  }

  @override
  void onInit() {
    super.onInit();
    fetchUserPlaylists();
    monitorLinkField();
  }

  void monitorLinkField() {
    link.value.addListener(() {
      isLinkEntered.value = link.value.text.trim().isNotEmpty;

      // Optional: clear audio if link entered
      if (isLinkEntered.value) {
        audioPath.value = '';
      }
    });
  }

  Future<void> pickImage() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) pickedImage.value = File(image.path);
  }

  Future<void> pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );
    if (result != null && result.files.single.path != null) {
      audioPath.value = result.files.single.path!;
    }
  }

  Future<bool> submitBanger() async {
    final titleVal = title.value.text.trim();
    final artistVal = Artist.value.text.trim();
    final descVal = Description.value.text.trim();
    final linkVal = link.value.text.trim();

    if (titleVal.isEmpty ||
        artistVal.isEmpty ||
        pickedImage.value == null ||
        (linkVal.isEmpty && audioPath.value.isEmpty)) {
      Get.snackbar("Error", "Please fill all required fields and add media.");
      return false;
    }

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final uid = AppConstants.userId;
      final now = Timestamp.now();

      final imageRef = FirebaseStorage.instance.ref().child(
        'images/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await imageRef.putFile(pickedImage.value!);
      final imageUrl = await imageRef.getDownloadURL();

      String audioUrl = '';
      if (linkVal.isNotEmpty) {
        audioUrl = linkVal;
      } else {
        final audioRef = FirebaseStorage.instance.ref().child(
          'audios/${DateTime.now().millisecondsSinceEpoch}.mp3',
        );
        await audioRef.putFile(File(audioPath.value));
        audioUrl = await audioRef.getDownloadURL();
      }

      final String id = DateTime.now().microsecondsSinceEpoch.toString();

      await FirebaseFirestore.instance.collection("Bangers").doc(id).set({
        'title': titleVal,
        'search_title': titleVal.toLowerCase(),
        'artist': artistVal,
        'link': linkVal,
        'description': descVal,
        'tags': Tags.value.text.split(' '),
        'playlistName': selectedPlaylist.value,
        'playlistId': selectedPlaylistId.value,
        'playlistImg': selectedPlaylistImage.value,
        'imageUrl': imageUrl,
        'audioUrl': audioUrl,
        'TotalLikes': 0,
        'Totalcomments': 0,
        'TotalShares': 0,
        'plays': 0,
        'comments': [],
        'Likes': [],
        'shares': [],
        'createdAt': now,
        'CreatedBy': uid,
        'genre': selectedGenre.value,
        'subGenre': selectedSubGenre.value,
        'id': id,
        'UserImage': AppConstants.userImg,
        'youtubeSong': true,
        'isRawLink': true,
        'isbanger': true,
      });

      if (selectedPlaylistId.value != '') {
        await addToPlaylistListField(
          docId: selectedPlaylistId.value,
          fieldName: 'bangers',
          valueToAdd: {
            'title': titleVal,
            'artist': artistVal,
            'imageUrl': imageUrl,
            'audioUrl': audioUrl,
            'bangerId': id,
            'youtubeSong': true,
            'isRawLink': true,
          },
        );
      }

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

      Get.back();
      Get.snackbar("Success", "Banger added successfully!");
      clearForm();
      return true;
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Failed to upload: $e");
      return false;
    }
  }

  void clearForm() {
    title.value.clear();
    Artist.value.clear();
    link.value.clear();
    Description.value.clear();
    Tags.value.clear();
    pickedImage.value = null;
    audioPath.value = '';
    isLinkEntered.value = false;
  }

  Future<void> fetchUserPlaylists() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('Playlist')
            .where('created By', isEqualTo: uid)
            .get();

    final titles = <String>['Select'];
    final ids = <String>[''];
    final images = <String>[''];

    for (var doc in snapshot.docs) {
      titles.add(doc['title'].toString());
      ids.add(doc.id);
      images.add(doc['image'].toString());
    }

    playlistItems.value = titles;
    playlistIds.value = ids;
    playlistImges.value = images;

    selectedPlaylist.value = titles.first;
    selectedPlaylistId.value = '';
    selectedPlaylistImage.value = '';
  }

  Future<void> addToPlaylistListField({
    required String docId,
    required String fieldName,
    required dynamic valueToAdd,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('Playlist')
          .doc(docId);
      await docRef.update({
        fieldName: FieldValue.arrayUnion([valueToAdd]),
      });
    } catch (e) {
      print('Error adding value to list: $e');
    }
  }
}
