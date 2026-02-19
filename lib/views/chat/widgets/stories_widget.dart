import 'package:banger_drop/consts/consts.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserProfileWidget extends StatelessWidget {
  final String imageUrl;
  final String name;
  final bool isOnline;
  final bool dimmed;

  const UserProfileWidget({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.isOnline,
    this.dimmed = false, // default to false
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Opacity(
          opacity: dimmed ? 0.4 : 1.0, // Dim the whole avatar if needed
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  color: appColors.textGrey,

                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.purpleAccent, width: 3),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.person,
                            size: 35.sp,
                            color: Colors.grey,
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                  ),
                ),
              ),
              if (name != 'My Story')
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green : appColors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Opacity(
          opacity: dimmed ? 0.4 : 1.0, // Dim the name text too
          child: SizedBox(
            width: 80,
            child: Text(
              name,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: appThemes.small.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
