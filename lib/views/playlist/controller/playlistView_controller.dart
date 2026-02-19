// playlist_detail_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class PlaylistDetailController extends GetxController {
  var playlistData = <String, dynamic>{}.obs;
  var isLoading = true.obs;
  var error = ''.obs;

  Future<void> fetchPlaylistById(String id) async {
    try {
      isLoading.value = true;
      final doc =
          await FirebaseFirestore.instance.collection('Playlist').doc(id).get();

      if (doc.exists) {
        playlistData.value = doc.data()!;
        error.value = '';
      } else {
        error.value = 'Playlist not found';
      }
    } catch (e) {
      error.value = 'Error fetching playlist: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
