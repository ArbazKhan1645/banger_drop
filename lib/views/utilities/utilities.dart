import 'package:get/route_manager.dart';
import 'package:get/state_manager.dart';

class Utilities {
  static void successMessege(String title, String message) {
    Get.snackbar(title, message);
  }
}
