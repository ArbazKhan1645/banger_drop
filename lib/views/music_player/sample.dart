// import 'package:banger_drop/views/music_player/controller/player_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class SimpleAudioPlayer extends StatelessWidget {
//   final String audioUrl;
//   final AudioPlayerController controller = Get.put(AudioPlayerController());

//   SimpleAudioPlayer({super.key, required this.audioUrl});

//   String formatTime(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     final seconds = twoDigits(duration.inSeconds.remainder(60));
//     return "$minutes:$seconds";
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Start playing automatically
//     controller.playAudio(audioUrl);

//     return Scaffold(
//       appBar: AppBar(title: const Text('Audio Player')),
//       body: Obx(() {
//         if (controller.hasError.value) {
//           return const Center(child: Text("Error loading audio."));
//         }

//         return Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Slider(
//                 min: 0,
//                 max: controller.duration.value.inSeconds.toDouble(),
//                 value:
//                     controller.position.value.inSeconds
//                         .clamp(0, controller.duration.value.inSeconds)
//                         .toDouble(),
//                 onChanged: controller.seekTo,
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(formatTime(controller.position.value)),
//                   Text(formatTime(controller.duration.value)),
//                 ],
//               ),
//               const SizedBox(height: 30),
//               IconButton(
//                 iconSize: 64,
//                 icon: Icon(
//                   controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
//                 ),
//                 onPressed: controller.togglePlayPause,
//               ),
//             ],
//           ),
//         );
//       }),
//     );
//   }
// }
