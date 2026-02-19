import 'dart:io';

import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/widgets/profile_textfield_wifget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class PersonalInfoView extends StatelessWidget {
  PersonalInfoView({Key? key}) : super(key: key);

  final controller = Get.put(PersonalInfoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/Picture1.png', fit: BoxFit.cover),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Obx(
                () => SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          BackButton(color: Colors.white),
                          const Spacer(),
                          controller.hasUnsavedChanges.value
                              ? TextButton(
                                onPressed: controller.saveProfileChanges,
                                child: const Text(
                                  "Save",
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                              : const SizedBox.shrink(),
                        ],
                      ),
                      // Profile Image
                      const SizedBox(height: 20),

                      ProfileField(
                        active: true,
                        title: 'Username',
                        controller: controller.nameController,
                        onChanged: (_) => controller.onFieldChanged(),
                      ),
                      const SizedBox(height: 12),

                      ProfileField(
                        active: false,
                        title: 'Email',
                        controller: controller.emailController,
                        onChanged: (_) => controller.onFieldChanged(),
                      ),
                      const SizedBox(height: 12),
                      ProfileField(
                        active: true,
                        title: 'First Name',
                        controller: controller.firstNameController,
                        onChanged: (_) => controller.onFieldChanged(),
                      ),
                      const SizedBox(height: 12),
                      ProfileField(
                        active: true,
                        title: 'Last Name',
                        controller: controller.lastNameController,
                        onChanged: (_) => controller.onFieldChanged(),
                      ),
                      const SizedBox(height: 12),

                      ProfileField(
                        active: true,
                        title: 'Phone',
                        controller: controller.phone,
                        onChanged: (_) => controller.onFieldChanged(),
                      ),
                      const SizedBox(height: 12),

                      DateProfileField(
                        title: 'Date of Birth',
                        controller: controller.dobController,
                        active: true,
                        onChanged:
                            controller
                                .onFieldChanged, // 👈 this makes the Save button appear
                      ),

                      const SizedBox(height: 12),

                      // CountryProfileField(
                      //   title: 'Country',
                      //   controller: controller.countryController,
                      //   active: true,
                      //   onChanged: (_) => controller.onFieldChanged(),
                      // ),
                      Obx(() {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Country :',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.purpleAccent,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.transparent,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  dropdownColor: appColors.purple,
                                  iconEnabledColor: Colors.white,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  hint: const Text(
                                    'Select Country',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  value:
                                      controller.selectedCountry.value.isEmpty
                                          ? null
                                          : controller.selectedCountry.value,
                                  items:
                                      controller.countryList.map((
                                        String country,
                                      ) {
                                        return DropdownMenuItem<String>(
                                          value: country,
                                          child: Text(country),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      controller.selectedCountry.value = value;
                                      controller.hasUnsavedChanges.value = true;
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      }),

                      SizedBox(height: 250),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PersonalInfoController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxString profileImageUrl = (AppConstants.userImg ?? '').obs;
  RxBool isLoading = false.obs;
  RxString points = (AppConstants.points ?? '0').obs;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();
  final phone = TextEditingController();
  final countryController = TextEditingController();
  final RxBool hasUnsavedChanges = false.obs;
  RxString selectedCountry = ''.obs;
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchUserData(AppConstants.userId);
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    super.onClose();
  }

  void onFieldChanged() {
    hasUnsavedChanges.value = true;
  }

  // Example country list
  List<String> countryList = [
    'Afghanistan',
    'Albania',
    'Algeria',
    'Andorra',
    'Angola',
    'Antigua and Barbuda',
    'Argentina',
    'Armenia',
    'Australia',
    'Austria',
    'Azerbaijan',
    'Bahamas',
    'Bahrain',
    'Bangladesh',
    'Barbados',
    'Belarus',
    'Belgium',
    'Belize',
    'Benin',
    'Bhutan',
    'Bolivia',
    'Bosnia and Herzegovina',
    'Botswana',
    'Brazil',
    'Brunei',
    'Bulgaria',
    'Burkina Faso',
    'Burundi',
    'Cabo Verde',
    'Cambodia',
    'Cameroon',
    'Canada',
    'Central African Republic',
    'Chad',
    'Chile',
    'China',
    'Colombia',
    'Comoros',
    'Congo (Congo-Brazzaville)',
    'Costa Rica',
    'Croatia',
    'Cuba',
    'Cyprus',
    'Czech Republic (Czechia)',
    'Democratic Republic of the Congo',
    'Denmark',
    'Djibouti',
    'Dominica',
    'Dominican Republic',
    'Ecuador',
    'Egypt',
    'El Salvador',
    'Equatorial Guinea',
    'Eritrea',
    'Estonia',
    'Eswatini (fmr. "Swaziland")',
    'Ethiopia',
    'Fiji',
    'Finland',
    'France',
    'Gabon',
    'Gambia',
    'Georgia',
    'Germany',
    'Ghana',
    'Greece',
    'Grenada',
    'Guatemala',
    'Guinea',
    'Guinea-Bissau',
    'Guyana',
    'Haiti',
    'Honduras',
    'Hungary',
    'Iceland',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland',
    'Israel',
    'Italy',
    'Jamaica',
    'Japan',
    'Jordan',
    'Kazakhstan',
    'Kenya',
    'Kiribati',
    'Kuwait',
    'Kyrgyzstan',
    'Laos',
    'Latvia',
    'Lebanon',
    'Lesotho',
    'Liberia',
    'Libya',
    'Liechtenstein',
    'Lithuania',
    'Luxembourg',
    'Madagascar',
    'Malawi',
    'Malaysia',
    'Maldives',
    'Mali',
    'Malta',
    'Marshall Islands',
    'Mauritania',
    'Mauritius',
    'Mexico',
    'Micronesia',
    'Moldova',
    'Monaco',
    'Mongolia',
    'Montenegro',
    'Morocco',
    'Mozambique',
    'Myanmar (formerly Burma)',
    'Namibia',
    'Nauru',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Nicaragua',
    'Niger',
    'Nigeria',
    'North Korea',
    'North Macedonia',
    'Norway',
    'Oman',
    'Pakistan',
    'Palau',
    'Palestine State',
    'Panama',
    'Papua New Guinea',
    'Paraguay',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Romania',
    'Russia',
    'Rwanda',
    'Saint Kitts and Nevis',
    'Saint Lucia',
    'Saint Vincent and the Grenadines',
    'Samoa',
    'San Marino',
    'Sao Tome and Principe',
    'Saudi Arabia',
    'Senegal',
    'Serbia',
    'Seychelles',
    'Sierra Leone',
    'Singapore',
    'Slovakia',
    'Slovenia',
    'Solomon Islands',
    'Somalia',
    'South Africa',
    'South Korea',
    'South Sudan',
    'Spain',
    'Sri Lanka',
    'Sudan',
    'Suriname',
    'Sweden',
    'Switzerland',
    'Syria',
    'Taiwan',
    'Tajikistan',
    'Tanzania',
    'Thailand',
    'Timor-Leste',
    'Togo',
    'Tonga',
    'Trinidad and Tobago',
    'Tunisia',
    'Turkey',
    'Turkmenistan',
    'Tuvalu',
    'Uganda',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Uruguay',
    'Uzbekistan',
    'Vanuatu',
    'Vatican City',
    'Venezuela',
    'Vietnam',
    'Yemen',
    'Zambia',
    'Zimbabwe',
  ];

  Future<void> fetchUserData(String userId) async {
    try {
      final docSnapshot =
          await _firestore.collection('users').doc(userId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        nameController.text = data['username'] ?? '';
        emailController.text = data['email'] ?? '';
        phone.text = data['phone'] ?? '';
        dobController.text = data['dob'] ?? '';
        countryController.text = data['country'] ?? '';
        selectedCountry.value = data['country'] ?? '';

        profileImageUrl.value = data['img'] ?? '';
        final fullName = data['name'] ?? '';
        final parts = fullName.trim().split(' ');
        firstNameController.text = parts.isNotEmpty ? parts.first : '';
        lastNameController.text =
            parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> saveProfileChanges() async {
    final uid = AppConstants.userId;
    final newUsername = nameController.text.trim();

    try {
      final userRef = _firestore.collection('users').doc(uid);
      final userDoc = await userRef.get();
      final oldUsername = userDoc.data()?['username'];

      if (oldUsername != null && newUsername != oldUsername) {
        await updateUsername(newUsername);
      }
      final fullName =
          '${firstNameController.text.trim()} ${lastNameController.text.trim()}';

      await userRef.set({
        'username': newUsername,
        'name': fullName,
        'email': emailController.text.trim(),
        'phone': phone.text.trim(),
        'dob': dobController.text.trim(),
        'country': selectedCountry.value,
        'img': profileImageUrl.value,
      }, SetOptions(merge: true));

      hasUnsavedChanges.value = false;
      Get.snackbar("Saved", "Profile updated successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to save changes: $e");
    }
  }

  Future<void> updateUsername(String newUsername) async {
    final userId = AppConstants.userId;
    final usernamesRef = _firestore.collection('usernames');
    final userDocRef = _firestore.collection('users').doc(userId);

    try {
      final newUsernameDoc = await usernamesRef.doc(newUsername).get();
      if (newUsernameDoc.exists) {
        Get.snackbar("Error", "Username already taken.");
        return;
      }

      final userDoc = await userDocRef.get();
      final oldUsername = userDoc.data()?['username'];
      if (oldUsername == null || oldUsername.isEmpty) {
        Get.snackbar("Error", "Old username not found.");
        return;
      }

      final oldUsernameDoc = await usernamesRef.doc(oldUsername).get();
      final oldData = oldUsernameDoc.data();
      if (oldData == null) {
        Get.snackbar("Error", "Old username data is missing.");
        return;
      }

      final batch = _firestore.batch();
      batch.update(userDocRef, {'username': newUsername, 'name': newUsername});
      batch.delete(usernamesRef.doc(oldUsername));
      batch.set(usernamesRef.doc(newUsername), {
        'uid': oldData['uid'],
        'email': oldData['email'],
      });

      await batch.commit();

      Get.snackbar("Success", "Username updated successfully.");
    } catch (e) {
      Get.snackbar("Error", "Failed to update username: $e");
    }
  }
}
