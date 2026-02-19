import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/notifications/notifications_services.dart';
import 'package:banger_drop/views/spalsh/spalsh_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/notifications/notifications_services.dart';
import 'package:banger_drop/views/spalsh/spalsh_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ExploreController extends GetxController {
  var playlists = <QueryDocumentSnapshot>[].obs;
  var searchText = ''.obs;
  var bangers = <QueryDocumentSnapshot>[].obs;
  var allPlaylists = <QueryDocumentSnapshot>[].obs;
  var selectedCategory = 'Recent'.obs;
  var isLoadingCategory = false.obs;
  List<Map<String, dynamic>> allUsers = [];
  List<QueryDocumentSnapshot> rawBangers = [];
  List<QueryDocumentSnapshot> rawPlaylists = [];

  @override
  void onInit() {
    super.onInit();
    _initializeWithErrorHandling();
  }

  // Centralized error recovery method
  Future<void> _recoverFromError() async {
    print("🔄 Recovering from error - refreshing users and category data...");
    try {
      await fetchAllUsers();
      await handleCategorySelection();
    } catch (e) {
      print("❌ Error during recovery: $e");
    }
  }

  // Safe wrapper for initialization
  Future<void> _initializeWithErrorHandling() async {
    try {
      await fetchAllUsers();
      await handleCategorySelection(); // load default category
    } catch (e) {
      print("❌ Error during initialization: $e");
      await _recoverFromError();
    }
  }

  Future<void> fetchAllUsers() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      allUsers =
          snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
      print("Fetched ${allUsers.length} users.");
    } catch (e) {
      print("Error fetching all users: $e");
      rethrow; // Re-throw to trigger error recovery in calling methods
    }
  }

  String? getUserNameByUid(String uid) {
    try {
      for (final user in allUsers) {
        if (user['uid'] == uid) {
          return user['name'] as String?;
        }
      }
      return null; // UID not found
    } catch (e) {
      print("Error getting user name: $e");
      _recoverFromError();
      return null;
    }
  }

  String? getUserImgByUid(String uid) {
    try {
      for (final user in allUsers) {
        if (user['uid'] == uid) {
          return user['img'] as String?;
        }
      }
      return null; // UID not found or image is missing
    } catch (e) {
      print("Error getting user image: $e");
      _recoverFromError();
      return null;
    }
  }

  Future<void> refreshData() async {
    try {
      await handleCategorySelection();
    } catch (e) {
      print("Error refreshing data: $e");
      await _recoverFromError();
    }
  }

  Future<void> fetchTopPlaylistsByPlays() async {
    try {
      final query = FirebaseFirestore.instance
          .collection('Playlist')
          .orderBy('plays', descending: true);

      allPlaylists.value = (await query.get()).docs;
    } catch (e) {
      print("Error fetching top playlists: $e");
      await _recoverFromError();
    }
  }

  Future<void> fetchTopBangersFuture() async {
    try {
      final baseQuery = FirebaseFirestore.instance
          .collection('Bangers')
          .orderBy('createdAt', descending: true);

      final snapshot = await baseQuery.get();
      rawBangers = snapshot.docs;
      filterBangers();
    } catch (e) {
      print("Error fetching bangers: $e");
      await _recoverFromError();
    }
  }

  Future<void> fetchPlaylistsFuture() async {
    try {
      final query = FirebaseFirestore.instance
          .collection('Playlist')
          .orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      rawPlaylists = snapshot.docs;
      filterPlaylists();
    } catch (e) {
      print("Error fetching playlists: $e");
      await _recoverFromError();
    }
  }

  void filterBangers() {
    try {
      final keyword = searchText.value.trim().toLowerCase();

      if (keyword.isEmpty) {
        bangers.value = rawBangers;
        return;
      }

      // 🔍 Match users by name
      final matchedUsers =
          allUsers.where((user) {
            final name = (user['name'] ?? '').toString().toLowerCase();
            return name.contains(keyword);
          }).toList();

      final matchedUids = matchedUsers.map((u) => u['uid']).toSet();

      // 🔍 Filter bangers
      bangers.value =
          rawBangers.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final title = (data['search_title'] ?? '').toString().toLowerCase();
            final playlist =
                (data['playlistName'] ?? '').toString().toLowerCase();
            final artist = (data['artist'] ?? '').toString().toLowerCase();

            final tags = (data['tags'] ?? []) as List<dynamic>;

            // Check if any tag contains the keyword
            final matchesTags = tags.any((tag) {
              final tagStr = tag.toString().toLowerCase();
              return tagStr.contains(keyword);
            });

            final matchesText =
                title.contains(keyword) ||
                playlist.contains(keyword) ||
                artist.contains(keyword) ||
                matchesTags;

            final matchesUser = matchedUids.contains(data['CreatedBy']);

            return matchesText || matchesUser;
          }).toList();
    } catch (e) {
      print("Error filtering bangers: $e");
      _recoverFromError();
    }
  }

  void filterPlaylists() {
    try {
      final keyword = searchText.value.trim().toLowerCase();

      if (keyword.isEmpty) {
        allPlaylists.value = rawPlaylists;
        return;
      }

      // 🔍 Match users by name
      final matchedUsers =
          allUsers.where((user) {
            final name = (user['name'] ?? '').toString().toLowerCase();
            return name.contains(keyword);
          }).toList();

      final matchedUids = matchedUsers.map((u) => u['uid']).toSet();

      // 🔍 Filter playlists
      allPlaylists.value =
          rawPlaylists.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final searchTitle =
                (data['search_title'] ?? '').toString().toLowerCase();
            final authorName =
                (data['authorName'] ?? '').toString().toLowerCase();
            final genre = (data['genre'] ?? '').toString().toLowerCase();
            final subGenre = (data['subGenre'] ?? '').toString().toLowerCase();

            final tags = (data['tags'] ?? []) as List<dynamic>;

            // Match keyword inside any tag
            final matchesTags = tags.any((tag) {
              final tagStr = tag.toString().toLowerCase();
              return tagStr.contains(keyword);
            });

            final matchesText =
                searchTitle.contains(keyword) ||
                authorName.contains(keyword) ||
                genre.contains(keyword) ||
                subGenre.contains(keyword) ||
                matchesTags;

            final matchesUser = matchedUids.contains(data['created By']);

            return matchesText || matchesUser;
          }).toList();
    } catch (e) {
      print("Error filtering playlists: $e");
      _recoverFromError();
    }
  }

  Future<void> fetchTop50Bangers() async {
    try {
      final query = FirebaseFirestore.instance
          .collection('Bangers')
          .orderBy('plays', descending: true)
          .limit(50);

      bangers.value = (await query.get()).docs;
    } catch (e) {
      print("Error fetching top 50 bangers: $e");
      await _recoverFromError();
    }
  }

  Future<void> fetchAllBangersByPlays() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('Bangers')
              .orderBy('plays', descending: true)
              .get();
      bangers.value = snapshot.docs;
    } catch (e) {
      print("Error fetching all bangers by plays: $e");
      await _recoverFromError();
    }
  }

  /// ========== CATEGORY HANDLER ==========
  Future<void> handleCategorySelection() async {
    isLoadingCategory.value = true;
    final category = selectedCategory.value;

    try {
      switch (category) {
        case 'Recent':
          await fetchPlaylistsFuture();
          await fetchTopBangersFuture();
          break;
        case 'Discover':
          await fetchShuffledPlaylist(); // shuffle can use filtered if needed
          await fetchShuffledBangers();
          break;
        case 'Top 50':
          await fetchTopPlaylistsByPlays();
          await fetchTop50Bangers();
          break;
        case 'Today\'s Hits':
          await fetchTopPlaylistsByPlays();
          await fetchAllBangersByPlays();
          break;
        case 'friends mix':
          await fetchBangersAndPlaylistsFromFollowersAndFollowing(
            FirebaseAuth.instance.currentUser!.uid,
          );
          break;
      }
    } catch (e) {
      print('Error in handleCategorySelection: $e');
      await _recoverFromError();
    } finally {
      isLoadingCategory.value = false;
    }
  }

  /// ========== LIKE/PLAY ==========

  Future<void> toggleLike({
    required String bangerId,
    required String userId,
    required String userName,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('Bangers')
          .doc(bangerId);
      final doc = await docRef.get();
      final likes = List<Map<String, dynamic>>.from(doc['Likes'] ?? []);
      final isLiked = likes.any((like) => like['id'] == userId);

      if (isLiked) {
        likes.removeWhere((like) => like['id'] == userId);
        await docRef.update({
          'Likes': likes,
          'TotalLikes': FieldValue.increment(-1),
        });
      } else {
        likes.add({'id': userId, 'name': userName});
        await docRef.update({
          'Likes': likes,
          'TotalLikes': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print("Error toggling like: $e");
      await _recoverFromError();
    }
  }

  Future<void> incrementPlaysOncePerUser(String bangerId, String userId) async {
    try {
      final bangerRef = FirebaseFirestore.instance
          .collection('Bangers')
          .doc(bangerId);
      final playDocRef = bangerRef.collection('plays').doc(userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final playSnap = await transaction.get(playDocRef);
        final bangerSnap = await transaction.get(bangerRef);

        if (!bangerSnap.exists) throw Exception('Banger not found');
        if (!playSnap.exists) {
          transaction.set(playDocRef, {'played': true});
          transaction.update(bangerRef, {'plays': FieldValue.increment(1)});
        }
      });
    } catch (e) {
      print("Error incrementing plays: $e");
      await _recoverFromError();
    }
  }

  Future<void> fetchBangersAndPlaylistsFromFollowersAndFollowing(
    String currentUserId,
  ) async {
    try {
      // Clear the existing data
      bangers.clear();
      allPlaylists.clear();

      final firestore = FirebaseFirestore.instance;

      // Step 1: Get followers
      final followersSnap =
          await firestore
              .collection('users')
              .doc(currentUserId)
              .collection('followers')
              .get();
      final followerIds = followersSnap.docs.map((doc) => doc.id).toSet();

      // Step 2: Get following
      final followingSnap =
          await firestore
              .collection('users')
              .doc(currentUserId)
              .collection('following')
              .get();
      final followingIds = followingSnap.docs.map((doc) => doc.id).toSet();

      // Step 3: Combine unique userIds
      final Set<String> relatedUserIds = {...followerIds, ...followingIds};

      if (relatedUserIds.isEmpty) {
        bangers.clear();
        allPlaylists.clear();
        return;
      }

      // Step 4: Fetch Bangers and Playlists where CreatedBy is in relatedUserIds
      final chunks = _splitList(
        relatedUserIds.toList(),
        10,
      ); // Firestore in query limit = 10
      List<QueryDocumentSnapshot> bangerResult = [];
      List<QueryDocumentSnapshot> playlistResult = [];

      for (final chunk in chunks) {
        // Fetch Bangers created by followers or following
        final bangersSnap =
            await firestore
                .collection('Bangers')
                .where('CreatedBy', whereIn: chunk)
                .orderBy('createdAt', descending: true)
                .get();
        bangerResult.addAll(bangersSnap.docs);

        // Fetch Playlists created by followers or following
        final playlistsSnap =
            await firestore
                .collection('Playlist')
                .where('created By', whereIn: chunk)
                .orderBy('createdAt', descending: true)
                .get();
        playlistResult.addAll(playlistsSnap.docs);
      }

      // Set the fetched Bangers and Playlists to respective observable variables
      bangers.value = bangerResult;
      allPlaylists.value = playlistResult;
    } catch (e) {
      print(
        "Error fetching bangers and playlists from followers/following: $e",
      );
      await _recoverFromError();
    }
  }

  // Helper function to split list into chunks of size n
  List<List<T>> _splitList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }

  Future<void> viewPlaylist(String playlistId, String userId) async {
    try {
      final playlistRef = FirebaseFirestore.instance
          .collection('Playlist')
          .doc(playlistId);
      final playDocRef = playlistRef.collection('plays').doc(userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final playSnap = await transaction.get(playDocRef);
        final playlistSnap = await transaction.get(playlistRef);

        if (!playlistSnap.exists) throw Exception('Playlist not found');
        if (!playSnap.exists) {
          transaction.set(playDocRef, {'played': true});
          transaction.update(playlistRef, {'plays': FieldValue.increment(1)});
        }
      });
    } catch (e) {
      print("Error viewing playlist: $e");
      await _recoverFromError();
    }
  }

  Future<void> fetchShuffledBangers() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('Bangers').get();

      final docs = snapshot.docs;
      docs.shuffle(); // 🔀 Shuffle the list randomly
      bangers.value = docs;
    } catch (e) {
      print("Error fetching shuffled bangers: $e");
      await _recoverFromError();
    }
  }

  Future<void> fetchShuffledPlaylist() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('Playlist').get();

      final docs = snapshot.docs;
      docs.shuffle(); // 🔀 Shuffle the list randomly
      playlists.value = docs;
    } catch (e) {
      print("Error fetching shuffled playlists: $e");
      await _recoverFromError();
    }
  }

  /// ========== UTIL ==========

  String getTimeAgoFromTimestamp(Timestamp timestamp) {
    try {
      final time = timestamp.toDate();
      final diff = DateTime.now().difference(time);
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 30)
        return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
      if (diff.inDays < 365) {
        final months = (diff.inDays / 30).floor();
        return '$months month${months > 1 ? 's' : ''} ago';
      }
      final years = (diff.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } catch (e) {
      print("Error getting time ago: $e");
      _recoverFromError();
      return 'Unknown time';
    }
  }
}

//user data model

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String img;
  final int points;
  final bool isOnline;
  final DateTime lastSeen;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.img,
    required this.points,
    required this.isOnline,
    required this.lastSeen,
  });

  factory AppUser.fromMap(Map<String, dynamic> data) {
    try {
      return AppUser(
        uid: data['uid'] ?? '',
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        img: data['img'] ?? '',
        points: data['points'] ?? 0,
        isOnline: data['isOnline'] ?? false,
        lastSeen: (data['lastSeen'] as Timestamp).toDate(),
      );
    } catch (e) {
      print("Error creating AppUser from map: $e");
      // Return a default user if creation fails
      return AppUser(
        uid: '',
        name: 'Unknown User',
        email: '',
        img: '',
        points: 0,
        isOnline: false,
        lastSeen: DateTime.now(),
      );
    }
  }
}

// class ExploreController extends GetxController {
//   var playlists = <QueryDocumentSnapshot>[].obs;
//   var searchText = ''.obs;
//   var bangers = <QueryDocumentSnapshot>[].obs;
//   var allPlaylists = <QueryDocumentSnapshot>[].obs;
//   var selectedCategory = 'Recent'.obs;
//   var isLoadingCategory = false.obs;
//   List<Map<String, dynamic>> allUsers = [];
//   List<QueryDocumentSnapshot> rawBangers = [];
//   List<QueryDocumentSnapshot> rawPlaylists = [];

//   @override
//   void onInit() {
//     super.onInit();
//     fetchAllUsers();

//     handleCategorySelection(); // load default category
//   }

//   Future<void> fetchAllUsers() async {
//     try {
//       final snapshot =
//           await FirebaseFirestore.instance.collection('users').get();
//       allUsers =
//           snapshot.docs
//               .map((doc) => doc.data() as Map<String, dynamic>)
//               .toList();
//       print("Fetched ${allUsers.length} users.");
//     } catch (e) {
//       print("Error fetching all users: $e");
//     }
//   }

//   String? getUserNameByUid(String uid) {
//     for (final user in allUsers) {
//       if (user['uid'] == uid) {
//         return user['name'] as String?;
//       }
//     }
//     return null; // UID not found
//   }

//   String? getUserImgByUid(String uid) {
//     for (final user in allUsers) {
//       if (user['uid'] == uid) {
//         return user['img'] as String?;
//       }
//     }
//     return null; // UID not found or image is missing
//   }

//   Future<void> refreshData() async {
//     await handleCategorySelection();
//   }

//   /// ========== PLAYLISTS ==========
//   // Future<void> fetchPlaylistsFuture() async {
//   //   final query = FirebaseFirestore.instance
//   //       .collection('Playlist')
//   //       .orderBy('created By', descending: true); // ✅ Sort latest first

//   //   if (searchText.value.isEmpty) {
//   //     allPlaylists.value = (await query.get()).docs;
//   //   } else {
//   //     final filteredQuery = FirebaseFirestore.instance
//   //         .collection('Playlist')
//   //         .where('search_title', isGreaterThanOrEqualTo: searchText.value)
//   //         .where(
//   //           'search_title',
//   //           isLessThanOrEqualTo: searchText.value + '\uf8ff',
//   //         )
//   //         .orderBy('search_title');
//   //     final snapshot = await filteredQuery.get();
//   //     allPlaylists.value = snapshot.docs;
//   //   }
//   // }

//   Future<void> fetchTopPlaylistsByPlays() async {
//     final query = FirebaseFirestore.instance
//         .collection('Playlist')
//         .orderBy('plays', descending: true);

//     allPlaylists.value = (await query.get()).docs;
//   }

//   /// ========== BANGERS ==========

//   Future<void> fetchTopBangersFuture() async {
//     final baseQuery = FirebaseFirestore.instance
//         .collection('Bangers')
//         .orderBy('createdAt', descending: true);

//     final snapshot = await baseQuery.get();
//     rawBangers = snapshot.docs;
//     filterBangers();
//   }

//   Future<void> fetchPlaylistsFuture() async {
//     final query = FirebaseFirestore.instance
//         .collection('Playlist')
//         .orderBy('createdAt', descending: true);

//     final snapshot = await query.get();
//     rawPlaylists = snapshot.docs;
//     filterPlaylists();
//   }

//   void filterBangers() {
//     final keyword = searchText.value.trim().toLowerCase();

//     if (keyword.isEmpty) {
//       bangers.value = rawBangers;
//       return;
//     }

//     // 🔍 Match users by name
//     final matchedUsers =
//         allUsers.where((user) {
//           final name = (user['name'] ?? '').toString().toLowerCase();
//           return name.contains(keyword);
//         }).toList();

//     final matchedUids = matchedUsers.map((u) => u['uid']).toSet();

//     // 🔍 Filter bangers
//     bangers.value =
//         rawBangers.where((doc) {
//           final data = doc.data() as Map<String, dynamic>;

//           final title = (data['search_title'] ?? '').toString().toLowerCase();
//           final playlist =
//               (data['playlistName'] ?? '').toString().toLowerCase();
//           final artist = (data['artist'] ?? '').toString().toLowerCase();

//           final tags = (data['tags'] ?? []) as List<dynamic>;

//           // Check if any tag contains the keyword
//           final matchesTags = tags.any((tag) {
//             final tagStr = tag.toString().toLowerCase();
//             return tagStr.contains(keyword);
//           });

//           final matchesText =
//               title.contains(keyword) ||
//               playlist.contains(keyword) ||
//               artist.contains(keyword) ||
//               matchesTags;

//           final matchesUser = matchedUids.contains(data['CreatedBy']);

//           return matchesText || matchesUser;
//         }).toList();
//   }

//   void filterPlaylists() {
//     final keyword = searchText.value.trim().toLowerCase();

//     if (keyword.isEmpty) {
//       allPlaylists.value = rawPlaylists;
//       return;
//     }

//     // 🔍 Match users by name
//     final matchedUsers =
//         allUsers.where((user) {
//           final name = (user['name'] ?? '').toString().toLowerCase();
//           return name.contains(keyword);
//         }).toList();

//     final matchedUids = matchedUsers.map((u) => u['uid']).toSet();

//     // 🔍 Filter playlists
//     allPlaylists.value =
//         rawPlaylists.where((doc) {
//           final data = doc.data() as Map<String, dynamic>;

//           final searchTitle =
//               (data['search_title'] ?? '').toString().toLowerCase();
//           final authorName =
//               (data['authorName'] ?? '').toString().toLowerCase();
//           final genre = (data['genre'] ?? '').toString().toLowerCase();
//           final subGenre = (data['subGenre'] ?? '').toString().toLowerCase();

//           final tags = (data['tags'] ?? []) as List<dynamic>;

//           // Match keyword inside any tag
//           final matchesTags = tags.any((tag) {
//             final tagStr = tag.toString().toLowerCase();
//             return tagStr.contains(keyword);
//           });

//           final matchesText =
//               searchTitle.contains(keyword) ||
//               authorName.contains(keyword) ||
//               genre.contains(keyword) ||
//               subGenre.contains(keyword) ||
//               matchesTags;

//           final matchesUser = matchedUids.contains(data['created By']);

//           return matchesText || matchesUser;
//         }).toList();
//   }

//   Future<void> fetchTop50Bangers() async {
//     final query = FirebaseFirestore.instance
//         .collection('Bangers')
//         .orderBy('plays', descending: true)
//         .limit(50);

//     bangers.value = (await query.get()).docs;
//   }

//   Future<void> fetchAllBangersByPlays() async {
//     final snapshot =
//         await FirebaseFirestore.instance
//             .collection('Bangers')
//             .orderBy('plays', descending: true)
//             .get();
//     bangers.value = snapshot.docs;
//   }

//   /// ========== CATEGORY HANDLER ==========
//   Future<void> handleCategorySelection() async {
//     isLoadingCategory.value = true;
//     final category = selectedCategory.value;

//     try {
//       switch (category) {
//         case 'Recent':
//           await fetchPlaylistsFuture();
//           await fetchTopBangersFuture();
//           break;
//         case 'Discover':
//           await fetchShuffledPlaylist(); // shuffle can use filtered if needed
//           await fetchShuffledBangers();
//           break;
//         case 'Top 50':
//           await fetchTopPlaylistsByPlays();
//           await fetchTop50Bangers();
//           break;
//         case 'Today’s Hits':
//           await fetchTopPlaylistsByPlays();
//           await fetchAllBangersByPlays();
//           break;
//         case 'friends mix':
//           await fetchBangersAndPlaylistsFromFollowersAndFollowing(
//             FirebaseAuth.instance.currentUser!.uid,
//           );
//           break;
//       }
//     } catch (e) {
//       print('Error in handleCategorySelection: $e');
//     } finally {
//       isLoadingCategory.value = false;
//     }
//   }

//   /// ========== LIKE/PLAY ==========

//   Future<void> toggleLike({
//     required String bangerId,
//     required String userId,
//     required String userName,
//   }) async {
//     final docRef = FirebaseFirestore.instance
//         .collection('Bangers')
//         .doc(bangerId);
//     final doc = await docRef.get();
//     final likes = List<Map<String, dynamic>>.from(doc['Likes'] ?? []);
//     final isLiked = likes.any((like) => like['id'] == userId);

//     if (isLiked) {
//       likes.removeWhere((like) => like['id'] == userId);
//       await docRef.update({
//         'Likes': likes,
//         'TotalLikes': FieldValue.increment(-1),
//       });
//     } else {
//       likes.add({'id': userId, 'name': userName});
//       await docRef.update({
//         'Likes': likes,
//         'TotalLikes': FieldValue.increment(1),
//       });
//     }
//   }

//   Future<void> incrementPlaysOncePerUser(String bangerId, String userId) async {
//     final bangerRef = FirebaseFirestore.instance
//         .collection('Bangers')
//         .doc(bangerId);
//     final playDocRef = bangerRef.collection('plays').doc(userId);

//     await FirebaseFirestore.instance.runTransaction((transaction) async {
//       final playSnap = await transaction.get(playDocRef);
//       final bangerSnap = await transaction.get(bangerRef);

//       if (!bangerSnap.exists) throw Exception('Banger not found');
//       if (!playSnap.exists) {
//         transaction.set(playDocRef, {'played': true});
//         transaction.update(bangerRef, {'plays': FieldValue.increment(1)});
//       }
//     });
//   }

//   Future<void> fetchBangersAndPlaylistsFromFollowersAndFollowing(
//     String currentUserId,
//   ) async {
//     try {
//       // Clear the existing data
//       bangers.clear();
//       allPlaylists.clear();

//       final firestore = FirebaseFirestore.instance;

//       // Step 1: Get followers
//       final followersSnap =
//           await firestore
//               .collection('users')
//               .doc(currentUserId)
//               .collection('followers')
//               .get();
//       final followerIds = followersSnap.docs.map((doc) => doc.id).toSet();

//       // Step 2: Get following
//       final followingSnap =
//           await firestore
//               .collection('users')
//               .doc(currentUserId)
//               .collection('following')
//               .get();
//       final followingIds = followingSnap.docs.map((doc) => doc.id).toSet();

//       // Step 3: Combine unique userIds
//       final Set<String> relatedUserIds = {...followerIds, ...followingIds};

//       if (relatedUserIds.isEmpty) {
//         bangers.clear();
//         allPlaylists.clear();
//         return;
//       }

//       // Step 4: Fetch Bangers and Playlists where CreatedBy is in relatedUserIds
//       final chunks = _splitList(
//         relatedUserIds.toList(),
//         10,
//       ); // Firestore in query limit = 10
//       List<QueryDocumentSnapshot> bangerResult = [];
//       List<QueryDocumentSnapshot> playlistResult = [];

//       for (final chunk in chunks) {
//         // Fetch Bangers created by followers or following
//         final bangersSnap =
//             await firestore
//                 .collection('Bangers')
//                 .where('CreatedBy', whereIn: chunk)
//                 .orderBy('createdAt', descending: true)
//                 .get();
//         bangerResult.addAll(bangersSnap.docs);

//         // Fetch Playlists created by followers or following
//         final playlistsSnap =
//             await firestore
//                 .collection('Playlist')
//                 .where('created By', whereIn: chunk)
//                 .orderBy('createdAt', descending: true)
//                 .get();
//         playlistResult.addAll(playlistsSnap.docs);
//       }

//       // Set the fetched Bangers and Playlists to respective observable variables
//       bangers.value = bangerResult;
//       allPlaylists.value = playlistResult;
//     } catch (e) {
//       print(
//         "Error fetching bangers and playlists from followers/following: $e",
//       );
//     }
//   }

//   // Helper function to split list into chunks of size n
//   List<List<T>> _splitList<T>(List<T> list, int chunkSize) {
//     final chunks = <List<T>>[];
//     for (var i = 0; i < list.length; i += chunkSize) {
//       chunks.add(
//         list.sublist(
//           i,
//           i + chunkSize > list.length ? list.length : i + chunkSize,
//         ),
//       );
//     }
//     return chunks;
//   }

//   Future<void> viewPlaylist(String playlistId, String userId) async {
//     final playlistRef = FirebaseFirestore.instance
//         .collection('Playlist')
//         .doc(playlistId);
//     final playDocRef = playlistRef.collection('plays').doc(userId);

//     await FirebaseFirestore.instance.runTransaction((transaction) async {
//       final playSnap = await transaction.get(playDocRef);
//       final playlistSnap = await transaction.get(playlistRef);

//       if (!playlistSnap.exists) throw Exception('Playlist not found');
//       if (!playSnap.exists) {
//         transaction.set(playDocRef, {'played': true});
//         transaction.update(playlistRef, {'plays': FieldValue.increment(1)});
//       }
//     });
//   }

//   Future<void> fetchShuffledBangers() async {
//     final snapshot =
//         await FirebaseFirestore.instance.collection('Bangers').get();

//     final docs = snapshot.docs;
//     docs.shuffle(); // 🔀 Shuffle the list randomly
//     bangers.value = docs;
//   }

//   Future<void> fetchShuffledPlaylist() async {
//     final snapshot =
//         await FirebaseFirestore.instance.collection('Playlist').get();

//     final docs = snapshot.docs;
//     docs.shuffle(); // 🔀 Shuffle the list randomly
//     playlists.value = docs;
//   }

//   /// ========== UTIL ==========

//   String getTimeAgoFromTimestamp(Timestamp timestamp) {
//     final time = timestamp.toDate();
//     final diff = DateTime.now().difference(time);
//     if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
//     if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
//     if (diff.inHours < 24) return '${diff.inHours}h ago';
//     if (diff.inDays < 30)
//       return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
//     if (diff.inDays < 365) {
//       final months = (diff.inDays / 30).floor();
//       return '$months month${months > 1 ? 's' : ''} ago';
//     }
//     final years = (diff.inDays / 365).floor();
//     return '$years year${years > 1 ? 's' : ''} ago';
//   }
// }

// //user data model

// class AppUser {
//   final String uid;
//   final String name;
//   final String email;
//   final String img;
//   final int points;
//   final bool isOnline;
//   final DateTime lastSeen;

//   AppUser({
//     required this.uid,
//     required this.name,
//     required this.email,
//     required this.img,
//     required this.points,
//     required this.isOnline,
//     required this.lastSeen,
//   });

//   factory AppUser.fromMap(Map<String, dynamic> data) {
//     return AppUser(
//       uid: data['uid'] ?? '',
//       name: data['name'] ?? '',
//       email: data['email'] ?? '',
//       img: data['img'] ?? '',
//       points: data['points'] ?? 0,
//       isOnline: data['isOnline'] ?? false,
//       lastSeen: (data['lastSeen'] as Timestamp).toDate(),
//     );
//   }
// }
