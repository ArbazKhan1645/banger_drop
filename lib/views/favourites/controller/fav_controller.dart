import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavouritesController extends GetxController {
  var isLoading = true.obs;

  List<String> favoriteBangers = [];
  var favoriteDocs = <DocumentSnapshot>[].obs; // ✅ Fixed here

  List<String> favTracks = [];
  var favTrackDocs =
      <DocumentSnapshot>[]
          .obs; // ✅ Make this reactive too if you want Obx to respond

  @override
  void onInit() {
    super.onInit();
    loadFavPlaylistsAndDocs();
    loadFavTracksAndDocs();
  }

  Future<void> printFav() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? favPlayList = prefs.getStringList('favPlayList') ?? [];
    print(favPlayList);
  }

  // For Playlists
  Future<void> loadFavPlaylistsAndDocs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? favPlayList = prefs.getStringList('favPlayList');

    if (favPlayList != null && favPlayList.isNotEmpty) {
      favoriteBangers = favPlayList;

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      favoriteDocs.clear();

      for (String id in favoriteBangers) {
        try {
          final doc = await firestore.collection('Playlist').doc(id).get();
          if (doc.exists) {
            favoriteDocs.add(doc);
            print('Fetched playlist doc with ID: $id');
          } else {
            print('No playlist doc found for ID: $id');
          }
        } catch (e) {
          print('Error fetching playlist doc for ID $id: $e');
        }
      }
    } else {
      favoriteBangers = [];
      print('No favorite playlists found.');
    }
  }

  // For Tracks
  Future<void> loadFavTracksAndDocs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? fav = prefs.getStringList('fav');

    if (fav != null && fav.isNotEmpty) {
      favTracks = fav;

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      favTrackDocs.clear();

      for (String id in favTracks) {
        try {
          final doc = await firestore.collection('Bangers').doc(id).get();
          if (doc.exists) {
            favTrackDocs.add(doc);
            print('Fetched banger doc with ID: $id');
          } else {
            print('No banger doc found for ID: $id');
          }
        } catch (e) {
          print('Error fetching banger doc for ID $id: $e');
        }
      }
    } else {
      favTracks = [];
      print('No favorite tracks found.');
    }
  }

  Future<Map<String, dynamic>?> getBangerById(String bangerId) async {
    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('Bangers')
              .doc(bangerId)
              .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        return data?..addAll({'id': docSnapshot.id}); // Include the document ID
      } else {
        print("Banger not found");
        return null;
      }
    } catch (e) {
      print("Error fetching banger: $e");
      return null;
    }
  }
}
