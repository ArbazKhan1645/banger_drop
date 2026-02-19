import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/notifications/notifications_services.dart';
import 'package:banger_drop/views/settings/devices/device_view_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DevicesView extends StatelessWidget {
  final String uid;

  const DevicesView({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DevicesController(uid));

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Picture1.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          Get.back();
                        },
                        icon: Icon(Icons.arrow_back, color: appColors.white),
                      ),
                      TextButton(
                        onPressed: () async {
                          NotificationServices FCM = NotificationServices();
                          final token = await FCM.getDeviceToken();
                          controller.confirmLogoutAllDevices(token!);
                        },
                        child: Text('Logout All', style: appThemes.small),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Obx(() {
                      if (controller.devices.isEmpty) {
                        return Center(
                          child: Text(
                            'No devices found',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: controller.devices.length,
                        itemBuilder: (context, index) {
                          final device = controller.devices[index];
                          final loggedInAt = device['loggedInAt']?.toDate();
                          final formattedTime =
                              loggedInAt != null
                                  ? DateFormat.yMMMd().add_jm().format(
                                    loggedInAt,
                                  )
                                  : 'Unknown time';

                          return Card(
                            color: Colors.transparent,
                            margin: EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                device['deviceName'] ?? 'Unknown Device',
                                style: appThemes.Medium,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Platform: ${device['platform'] ?? 'N/A'}',
                                    style: appThemes.small,
                                  ),
                                  Text(
                                    'Logged in at: $formattedTime',
                                    style: appThemes.Medium,
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.logout, color: Colors.red),
                                onPressed: () {
                                  controller.removeDevice(device['token']);
                                },
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
