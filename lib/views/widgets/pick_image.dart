import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:image_picker/image_picker.dart';

class PickImage extends StatelessWidget {
  const PickImage({
    super.key,
    required ImagePicker picker,
    required this.pickedImage,
  }) : _picker = picker;

  final ImagePicker _picker;
  final Rx<File?> pickedImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Wrap(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => Get.back(),

                child: Icon(Icons.close),
              ),
            ],
          ),
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text("Pick from Camera"),
            onTap: () async {
              final XFile? image = await _picker.pickImage(
                source: ImageSource.camera,
              );
              if (image != null) {
                pickedImage.value = File(image.path);
              }
              Get.back();
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text("Pick from Gallery"),
            onTap: () async {
              final XFile? image = await _picker.pickImage(
                source: ImageSource.gallery,
              );
              if (image != null) {
                pickedImage.value = File(image.path);
              }
              Get.back();
            },
          ),
          // ListTile(
          //   leading: Icon(Icons.close),
          //   title: Text("Cancel"),
          // ),
        ],
      ),
    );
  }
}
