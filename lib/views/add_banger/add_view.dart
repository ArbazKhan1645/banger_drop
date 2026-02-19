import 'package:banger_drop/views/add_banger/add_banger.dart';
import 'package:banger_drop/views/add_playlist.dart/add_playlist_view.dart';
import 'package:flutter/material.dart';
import 'package:banger_drop/views/add_banger/widgets/add_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/instance_manager.dart'; // Make sure SplitContainer is defined here

class AddView extends StatefulWidget {
  const AddView({super.key});

  @override
  State<AddView> createState() => _AddViewState();
}

class _AddViewState extends State<AddView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    'assets/images/Picture1.png',
                  ), // Replace with your image path
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Centered SplitContainer
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: 300.h),
              child: SplitContainer(
                leftTap: () {
                  Get.to(() => AddBanger());
                },
                rightTap: () {
                  Get.to(() => AddPlayListView());
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
