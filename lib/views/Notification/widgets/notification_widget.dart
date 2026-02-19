import 'package:banger_drop/consts/consts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class NotificationTile extends StatelessWidget {
  final String leadingImageUrl;
  final String title;
  final String subtitle;
  final String timeAgo;
  final bool showTrailingImage;
  final String? trailingImageUrl;

  const NotificationTile({
    super.key,
    required this.leadingImageUrl,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    this.showTrailingImage = false,
    this.trailingImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CachedNetworkImage(
        imageUrl: leadingImageUrl,
        placeholder:
            (context, url) => const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person),
            ),
        errorWidget:
            (context, url, error) => const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.black),
            ),
        imageBuilder:
            (context, imageProvider) =>
                CircleAvatar(backgroundImage: imageProvider),
      ),

      title: Text(title, style: TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.white70)),
      trailing:
          showTrailingImage
              ? ClipRRect(
                borderRadius: BorderRadius.circular(
                  8,
                ), // customize the corner radius
                child: CachedNetworkImage(
                  imageUrl: trailingImageUrl ?? '',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        width: 40,
                        height: 40,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, color: Colors.white70),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        width: 40,
                        height: 40,
                        color: Colors.white,
                        child: const Icon(Icons.image, color: Colors.black),
                      ),
                ),
              )
              : null,
    );
  }
}
