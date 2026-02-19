import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TimeFilter { AllTime, Daily, Weekly, Monthly }

class LeaderboardController extends GetxController {
  RxList<Map<String, dynamic>> leaderboard = <Map<String, dynamic>>[].obs;
  Rx<TimeFilter> selectedFilter = TimeFilter.AllTime.obs;

  @override
  void onInit() {
    super.onInit();
    getLeaderboardData();
  }

  void changeFilter(TimeFilter filter) {
    selectedFilter.value = filter;
    getLeaderboardData();
  }

  Future<void> getLeaderboardData() async {
    try {
      final allUsersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final now = DateTime.now();
      DateTime startTime;

      switch (selectedFilter.value) {
        case TimeFilter.Daily:
          startTime = DateTime(now.year, now.month, now.day);
          break;
        case TimeFilter.Weekly:
          startTime = now.subtract(Duration(days: now.weekday - 1));
          break;
        case TimeFilter.Monthly:
          startTime = DateTime(now.year, now.month);
          break;
        case TimeFilter.AllTime:
          startTime = DateTime(1970); // beginning of time
          break;
      }

      List<Map<String, dynamic>> usersWithFilteredPoints = [];

      for (var doc in allUsersSnapshot.docs) {
        final data = doc.data();

        // 🔴 Skip if 'uid' is missing or null
        if (!data.containsKey('uid') || data['uid'] == null) continue;

        final history = List<Map<String, dynamic>>.from(
          (data['pointsHistory'] ?? []),
        );

        int total = 0;

        for (var entry in history) {
          if (entry.containsKey('timestamp')) {
            final ts = entry['timestamp'];
            if (ts is Timestamp && ts.toDate().isAfter(startTime)) {
              total += ((entry['points'] ?? 0) as num).toInt();
            }
          }
        }

        if (selectedFilter.value == TimeFilter.AllTime) {
          total = data['points'] ?? 0;
        }

        usersWithFilteredPoints.add({
          'username': data['name'] ?? '',
          'points': total,
          'profileImage': data['img'] ?? '',
          'uid': data['uid'],
        });
      }

      usersWithFilteredPoints.sort(
        (a, b) => b['points'].compareTo(a['points']),
      );

      leaderboard.value = usersWithFilteredPoints.skip(3).toList();
    } catch (e) {
      print("Error getting leaderboard: $e");
      leaderboard.clear();
    }
  }
}
