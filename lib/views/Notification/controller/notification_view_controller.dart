// import 'package:banger_drop/views/Notification/notification_view.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../../../consts/consts.dart';

// class NotificationViewController extends GetxController {
//   final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

//   Future<void> markNotificationsAsSeen() async {
//     final querySnapshot =
//         await FirebaseFirestore.instance
//             .collection('notifications')
//             .where('bangerOwnerId', isEqualTo: currentUserId)
//             .get();

//     final batch = FirebaseFirestore.instance.batch();
//     for (var doc in querySnapshot.docs) {
//       final data = doc.data();
//       final seenBy = List<String>.from(data['seenBy'] ?? []);
//       if (!seenBy.contains(currentUserId)) {
//         seenBy.add(currentUserId);
//         batch.update(doc.reference, {'seenBy': seenBy});
//       }
//     }
//     await batch.commit();
//   }

//   Future<Map<String, dynamic>?> getBangerById(String bangerId) async {
//     try {
//       final docSnapshot =
//           await FirebaseFirestore.instance
//               .collection('Bangers')
//               .doc(bangerId)
//               .get();

//       if (docSnapshot.exists) {
//         final data = docSnapshot.data();
//         return data?..addAll({'id': docSnapshot.id});
//       } else {
//         print("Banger not found");
//         return null;
//       }
//     } catch (e) {
//       print("Error fetching banger: $e");
//       return null;
//     }
//   }

//   // Check if current user is following the target user
//   Future<bool> checkIfFollowing(String targetUserId) async {
//     final doc =
//         await FirebaseFirestore.instance
//             .collection('users')
//             .doc(currentUserId)
//             .collection('following')
//             .doc(targetUserId)
//             .get();
//     return doc.exists;
//   }

//   // Check if current user has sent a follow request to target user
//   Future<bool> checkIfRequested(String targetUserId) async {
//     final query =
//         await FirebaseFirestore.instance
//             .collection('notifications')
//             .where('type', isEqualTo: 'followrequest')
//             .where('bangerOwnerId', isEqualTo: targetUserId)
//             .where('status', isEqualTo: 'pending')
//             .get();

//     return query.docs.any((doc) {
//       final users = List<Map<String, dynamic>>.from(doc['users']);
//       return users.any((u) => u['uid'] == currentUserId);
//     });
//   }

//   // Initialize follow states for a user
//   Future<void> initializeFollowState(String userId) async {
//     if (followStates.containsKey(userId)) return;

//     final isFollowing = await checkIfFollowing(userId);
//     final hasRequested = await checkIfRequested(userId);

//     followStates[userId] = isFollowing;
//     requestStates[userId] = hasRequested;
//     loadingStates[userId] = false;
//   }

//   // Send follow request (similar to your sendFollowRequestToggle function)
//   Future<void> sendFollowRequest(String targetUserId) async {
//     loadingStates[targetUserId] = true;

//     try {
//       // Check if already following
//       final isFollowing = await checkIfFollowing(targetUserId);
//       if (isFollowing) {
//         followStates[targetUserId] = true;
//         requestStates[targetUserId] = false;
//         loadingStates[targetUserId] = false;
//         return;
//       }

//       // Check if request already sent
//       final hasRequested = await checkIfRequested(targetUserId);
//       if (hasRequested) {
//         requestStates[targetUserId] = true;
//         loadingStates[targetUserId] = false;
//         return;
//       }

//       // Send follow request notification
//       await FirebaseFirestore.instance.collection('notifications').add({
//         "bangerId": "",
//         "bangerOwnerId": targetUserId,
//         "type": "followrequest",
//         "users": [
//           {
//             "uid": currentUserId,
//             "name": AppConstants.userName,
//             "img": AppConstants.userImg,
//           },
//         ],
//         "bangerImg": "",
//         "timestamp": Timestamp.now(),
//         "status": "pending",
//         "seenBy": [],
//       });

//       requestStates[targetUserId] = true;
//       loadingStates[targetUserId] = false;

//       // TODO: Send FCM notification if user has followUp notifications enabled
//       // You can implement this similar to your original code
//     } catch (e) {
//       print("Error sending follow request: $e");

//       loadingStates[targetUserId] = false;
//     }
//   }

//   final Map<String, bool> followStates = {};
//   final Map<String, bool> requestStates = {};
//   final Map<String, bool> loadingStates = {};

//   Widget buildFollowButton(String userId) {
//     // Initialize state if not already done
//     if (!followStates.containsKey(userId)) {
//       initializeFollowState(userId);
//       return const SizedBox(
//         width: 80,
//         height: 32,
//         child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
//       );
//     }

//     final isFollowing = followStates[userId] ?? false;
//     final hasRequested = requestStates[userId] ?? false;
//     final isLoading = loadingStates[userId] ?? false;

//     if (isLoading) {
//       return const SizedBox(
//         width: 80,
//         height: 32,
//         child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
//       );
//     }

//     String buttonText;
//     Color buttonColor;
//     VoidCallback? onTap;

//     if (isFollowing) {
//       buttonText = "Following";
//       buttonColor = Colors.grey;
//       onTap = null; // Disable tap
//     } else if (hasRequested) {
//       buttonText = "Request Sent";
//       buttonColor = Colors.orange;
//       onTap = null; // Disable tap
//     } else {
//       buttonText = "Follow Back";
//       buttonColor = appColors.purple;
//       onTap = () => sendFollowRequest(userId);
//     }

//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         decoration: BoxDecoration(
//           color: buttonColor,
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Text(
//           buttonText,
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 12,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ),
//     );
//   }
// }
