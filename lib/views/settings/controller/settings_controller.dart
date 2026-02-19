import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class SettingsController extends GetxController {
  var selectedLanguage = 'English'.obs;

  void changeLanguage(String lang) {
    selectedLanguage.value = lang;
  }
}
