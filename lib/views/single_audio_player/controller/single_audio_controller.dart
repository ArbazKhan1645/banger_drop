import 'package:banger_drop/views/music_player/controller/player_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

class SingleBangerPlayerController extends GetxController {
  final audioPlayer = AudioPlayer();

  var bangers = <dynamic>[];
  var currentIndex = 0.obs;
  var currentSong = <String, dynamic>{}.obs;

  var isPlaying = false.obs;
  var position = Duration.zero.obs;
  var duration = Duration.zero.obs;
  var error = ''.obs;
  var repeatOne = false.obs;
  var isNextDisabled = false.obs;
  var isLoading = false.obs;

  Future<void> loadBangerList(List<dynamic> all, int index) async {
    try {
      final newSongId = all[index]['id'];

      if (currentSong['id'] == newSongId) {
        return; // Already playing the same song
      }

      await audioPlayer.stop(); // 🛑 stop previous
      bangers = all;
      currentIndex.value = index;
      await _playCurrent();
    } catch (e) {
      error.value = 'Load error: $e';
    }
  }

  void pauseOtherPlayerIfRunning() {
    if (Get.isRegistered<AudioPlayerController>()) {
      final otherController = Get.find<AudioPlayerController>();
      otherController.stop();
    }
  }

  void toggleRepeat() {
    repeatOne.value = !repeatOne.value;
  }

  Future<void> stop() async {
    try {
      await audioPlayer.stop();
    } catch (_) {}
    isPlaying.value = false;
  }

  bool _isListening = false;
  Future<void> _playCurrent() async {
    pauseOtherPlayerIfRunning(); // 👈 pause the other player

    error.value = '';
    isLoading.value = true;
    isPlaying.value = false;

    try {
      int tries = 0;

      // ✅ Skip if youtubeSong is true (defaults to false if missing)
      while (tries < bangers.length &&
          (bangers[currentIndex.value]['youtubeSong'] == true)) {
        currentIndex.value = (currentIndex.value + 1) % bangers.length;
        tries++;
      }

      final data = bangers[currentIndex.value];
      final audioUrl = data['audioUrl'] ?? '';

      if (audioUrl.isEmpty) throw Exception("No audio URL found");

      currentSong.value = {
        'title': data['title'] ?? '',
        'artist': data['artist'] ?? '',
        'imageUrl': data['imageUrl'] ?? '',
        'audioUrl': audioUrl,
        'id': data['id'],
      };

      await audioPlayer.setUrl(audioUrl);
      duration.value = audioPlayer.duration ?? Duration.zero;
      _startListeningToPlayerState();
      await audioPlayer.play();
    } catch (e) {
      error.value = 'Playback error: $e';
      isLoading.value = false;
    }
  }

  void _startListeningToPlayerState() {
    if (_isListening) return;
    _isListening = true;

    audioPlayer.positionStream.listen((p) => position.value = p);

    audioPlayer.durationStream.listen((d) {
      if (d != null) duration.value = d;
    });

    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.ready) {
        isLoading.value = false;
      }

      if (state.processingState == ProcessingState.completed) {
        if (repeatOne.value) {
          audioPlayer.seek(Duration.zero);
          audioPlayer.play();
        } else {
          playNext();
        }
      }

      isPlaying.value = state.playing;
    });
  }

  void playNext() async {
    if (isNextDisabled.value) return;
    isNextDisabled.value = true;

    int nextIndex = currentIndex.value;

    for (int i = 0; i < bangers.length; i++) {
      nextIndex = (nextIndex + 1) % bangers.length;
      final data = bangers[nextIndex];
      if (data['youtubeSong'] != true) {
        currentIndex.value = nextIndex;
        await _playCurrent();
        break;
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    isNextDisabled.value = false;
  }

  void playPrevious() async {
    if (isNextDisabled.value) return;
    isNextDisabled.value = true;

    int prevIndex = currentIndex.value;

    for (int i = 0; i < bangers.length; i++) {
      prevIndex = (prevIndex - 1 + bangers.length) % bangers.length;
      final data = bangers[prevIndex];
      if (data['youtubeSong'] != true) {
        currentIndex.value = prevIndex;
        await _playCurrent();
        break;
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    isNextDisabled.value = false;
  }

  void togglePlayPause() {
    if (audioPlayer.playerState.processingState == ProcessingState.ready) {
      if (audioPlayer.playing) {
        audioPlayer.pause();
      } else {
        audioPlayer.play();
      }
    }
  }

  void seekTo(double fraction) {
    final pos = duration.value * fraction;
    audioPlayer.seek(pos);
  }

  Future<void> loadSingleBangerById(String bangerId) async {
    try {
      isLoading.value = true;
      error.value = '';
      await audioPlayer.stop();

      // Fetch the banger from Firestore
      final doc =
          await FirebaseFirestore.instance
              .collection('Bangers')
              .doc(bangerId)
              .get();

      if (!doc.exists) {
        throw Exception("Banger not found");
      }

      final data = doc.data()!;
      final audioUrl = data['audioUrl'] ?? '';

      if (audioUrl.isEmpty) throw Exception("No audio URL found");

      currentSong.value = {
        'title': data['title'] ?? '',
        'artist': data['artist'] ?? '',
        'imageUrl': data['imageUrl'] ?? '',
        'audioUrl': audioUrl,
        'id': data['id'] ?? bangerId,
        'description': data['description'] ?? '',
        'CreatedBy': data['CreatedBy'] ?? '',
      };

      await audioPlayer.setUrl(audioUrl);
      duration.value = audioPlayer.duration ?? Duration.zero;
      _startListeningToPlayerState();
      await audioPlayer.play();
    } catch (e) {
      error.value = 'Playback error: $e';
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    audioPlayer.dispose();
    super.onClose();
  }
}
