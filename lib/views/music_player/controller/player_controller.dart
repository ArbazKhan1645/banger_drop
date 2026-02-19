import 'package:banger_drop/views/single_audio_player/controller/single_audio_controller.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:banger_drop/consts/consts.dart';

class AudioPlayerController extends GetxController {
  final audioPlayer = AudioPlayer();

  var playlist = <DocumentSnapshot>[];
  var currentIndex = 0.obs;
  var currentSong = <String, dynamic>{}.obs;

  var isPlaying = false.obs;
  var position = Duration.zero.obs;
  var duration = Duration.zero.obs;

  var error = ''.obs;
  var repeatOne = false.obs;
  var isLoading = false.obs;
  var isReady = false.obs;

  // Social interaction data
  final RxInt totalLikes = 0.obs;
  final RxInt totalShares = 0.obs;
  final RxList likesList = [].obs;
  final RxBool isLiked = false.obs;

  @override
  void onInit() {
    super.onInit();
    _listenToPlayerState();
  }

  void toggleRepeat() {
    repeatOne.value = !repeatOne.value;
  }

  void loadPlaylist(List<DocumentSnapshot> songs, int startIdx) {
    if (isLoading.value) return;

    playlist = songs;

    int idx = startIdx;
    bool found = false;

    // Check current index first
    if (!_isYouTubeSong(playlist[idx])) {
      found = true;
    } else {
      // Try backward
      for (int i = idx - 1; i >= 0; i--) {
        if (!_isYouTubeSong(playlist[i])) {
          idx = i;
          found = true;
          break;
        }
      }
      // Then try forward
      if (!found) {
        for (int i = idx + 1; i < playlist.length; i++) {
          if (!_isYouTubeSong(playlist[i])) {
            idx = i;
            found = true;
            break;
          }
        }
      }
    }

    if (!found) {
      error.value = "No valid songs found in playlist.";
      return;
    }

    currentIndex.value = idx;
    _playCurrentSong();
  }

  bool _isYouTubeSong(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return data['youtubeSong'] == true;
  }

  Future<void> _playCurrentSong() async {
    pauseOtherPlayerIfRunning();

    error.value = '';
    isLoading.value = true;
    isReady.value = false;

    try {
      final rawDoc = playlist[currentIndex.value];
      final data = rawDoc.data() as Map<String, dynamic>;
      final docId = rawDoc.id;

      final audioUrl = data['audioUrl'] ?? '';
      if (audioUrl.isEmpty) throw Exception("Audio URL is missing.");

      currentSong.value = {
        'id': docId,
        'title': data['title'] ?? 'Unknown Title',
        'artist': data['artist'] ?? 'Unknown Artist',
        'audioUrl': audioUrl,
        'imageUrl': data['imageUrl'] ?? '',
        'year': data['year'] ?? 'N/A',
        'description': data['description'] ?? '',
      };

      await audioPlayer.stop();
      await audioPlayer.setUrl(audioUrl);
      isReady.value = true;

      loadSocialData(docId, AppConstants.userId);

      await audioPlayer.play();
    } catch (e) {
      error.value = "Error loading audio:\n$e";
    } finally {
      isLoading.value = false;
    }
  }

  void loadSocialData(String bangerId, String currentUserId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('Bangers')
            .doc(bangerId)
            .get();

    if (doc.exists) {
      final data = doc.data()!;
      final likes = List<Map<String, dynamic>>.from(data['Likes'] ?? []);
      final total = data['TotalLikes'] ?? 0;
      final shares = data['TotalShares'] ?? 0;

      totalLikes.value = total;
      totalShares.value = shares;
      likesList.value = likes;
      isLiked.value = likes.any((like) => like['id'] == currentUserId);
    }
  }

  void _listenToPlayerState() {
    audioPlayer.positionStream.listen((p) => position.value = p);

    audioPlayer.durationStream.listen((d) {
      if (d != null) duration.value = d;
    });

    audioPlayer.playerStateStream.listen((state) {
      final playing = state.playing;
      final processing = state.processingState;

      if (processing == ProcessingState.completed) {
        if (repeatOne.value) {
          audioPlayer.seek(Duration.zero);
          audioPlayer.play();
        } else {
          playNextSong();
        }
      }

      isPlaying.value = (playing && processing == ProcessingState.ready);
    });
  }

  void togglePlayPause() {
    if (audioPlayer.playing) {
      audioPlayer.pause();
    } else {
      audioPlayer.play();
    }
  }

  void playNextSong() async {
    int total = playlist.length;
    int nextIndex = currentIndex.value;

    // Try to loop through the entire playlist once
    for (int i = 0; i < total; i++) {
      nextIndex = (nextIndex + 1) % total; // auto-loop
      final doc = playlist[nextIndex];
      if (!_isYouTubeSong(doc)) {
        currentIndex.value = nextIndex;
        await _playCurrentSong();
        return;
      }
    }

    // If no valid songs found even after looping
    print('No valid non-YouTube songs found in playlist.');
  }

  void playPreviousSong() async {
    int total = playlist.length;
    int prevIndex = currentIndex.value;

    for (int i = 0; i < total; i++) {
      prevIndex = (prevIndex - 1 + total) % total; // loop backward
      final doc = playlist[prevIndex];
      if (!_isYouTubeSong(doc)) {
        currentIndex.value = prevIndex;
        await _playCurrentSong();
        return;
      }
    }

    print('No valid non-YouTube songs found in playlist.');
  }

  void seekTo(double fraction) {
    final newPosition = duration.value * fraction;
    audioPlayer.seek(newPosition);
  }

  void stop() {
    audioPlayer.stop();
    isPlaying.value = false;
  }

  void reset() async {
    try {
      await audioPlayer.stop();
      await audioPlayer.dispose();
    } catch (e) {
      print('Reset error: $e');
    }
    isPlaying.value = false;
    isLoading.value = false;
    isReady.value = false;
  }

  void pauseOtherPlayerIfRunning() {
    if (Get.isRegistered<SingleBangerPlayerController>()) {
      final otherController = Get.find<SingleBangerPlayerController>();
      otherController.stop();
    }
  }

  @override
  void onClose() {
    reset();
    super.onClose();
  }
}
