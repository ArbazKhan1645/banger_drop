import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/chat/chat_view.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_typedefs/rx_typedefs.dart';
import 'package:get/utils.dart';

class MessageTile extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String messageSummary;
  final String time;
  final bool online;
  final Callback ontap;
  final Callback profileTap;

  const MessageTile({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.messageSummary,
    required this.time,
    required this.online,
    required this.ontap,
    required this.profileTap,
  });
  String _shorten(String text, {int maxLength = 15}) {
    return text.length > maxLength
        ? '${text.substring(0, maxLength)}...'
        : text;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ontap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(
            0xFF2B0040,
          ).withOpacity(.1), // Background color (dark purple)
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Profile Picture with pink border
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.pinkAccent, width: 3),
              ),
              child: GestureDetector(
                onTap: () {
                  profileTap();
                },
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, size: 30),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name and message info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name, style: appThemes.Medium),
                  const SizedBox(height: 4),
                  Text(
                    '${_shorten(messageSummary)} - $time',
                    style: appThemes.small.copyWith(fontFamily: 'Sans'),
                  ),
                ],
              ),
            ),

            // Red dot for unread
            online
                ? Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                )
                : SizedBox(),
          ],
        ),
      ),
    );
  }
}
