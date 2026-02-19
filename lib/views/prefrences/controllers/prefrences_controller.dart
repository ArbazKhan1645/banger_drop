import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrefrencesController extends GetxController {
  Future<void> incrementUserPoints(String userId, int incrementBy) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {
      await _firestore.collection('users').doc(userId).update({
        'points': FieldValue.increment(incrementBy),
      });
      print('Points updated successfully');
    } catch (e) {
      print('Failed to update points: $e');
    }
  }
}
